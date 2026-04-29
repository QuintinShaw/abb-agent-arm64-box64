#define _GNU_SOURCE
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct libmnt_context {
    int unused;
};

struct libmnt_iter {
    size_t idx;
};

struct libmnt_fs {
    int id;
    int parent_id;
    char *source;
    char *target;
};

struct libmnt_table {
    struct libmnt_fs *items;
    size_t count;
    size_t cap;
};

static void unescape_mount(char *s) {
    char *r = s;
    char *w = s;
    while (*r) {
        if (*r == '\\' && isdigit((unsigned char)r[1]) &&
            isdigit((unsigned char)r[2]) && isdigit((unsigned char)r[3])) {
            int v = (r[1] - '0') * 64 + (r[2] - '0') * 8 + (r[3] - '0');
            *w++ = (char)v;
            r += 4;
        } else {
            *w++ = *r++;
        }
    }
    *w = '\0';
}

static int table_add(struct libmnt_table *tb, int id, int parent, const char *source, const char *target) {
    if (!tb || !source || !target) return -1;
    if (tb->count == tb->cap) {
        size_t next = tb->cap ? tb->cap * 2 : 32;
        struct libmnt_fs *items = realloc(tb->items, next * sizeof(*items));
        if (!items) return -1;
        tb->items = items;
        tb->cap = next;
    }
    struct libmnt_fs *fs = &tb->items[tb->count++];
    fs->id = id;
    fs->parent_id = parent;
    fs->source = strdup(source);
    fs->target = strdup(target);
    if (!fs->source || !fs->target) return -1;
    unescape_mount(fs->source);
    unescape_mount(fs->target);
    return 0;
}

static int parse_mountinfo(struct libmnt_table *tb, const char *path) {
    FILE *fp = fopen(path, "r");
    if (!fp) return -1;

    char *line = NULL;
    size_t len = 0;
    while (getline(&line, &len, fp) != -1) {
        char *sep = strstr(line, " - ");
        if (!sep) continue;
        *sep = '\0';
        char *post = sep + 3;

        int id = 0;
        int parent = 0;
        char root[4096] = {0};
        char target[4096] = {0};
        if (sscanf(line, "%d %d %*s %4095s %4095s", &id, &parent, root, target) != 4) {
            continue;
        }

        char fstype[256] = {0};
        char source[4096] = {0};
        if (sscanf(post, "%255s %4095s", fstype, source) != 2) {
            continue;
        }
        table_add(tb, id, parent, source, target);
    }

    free(line);
    fclose(fp);
    return 0;
}

static int parse_mounts(struct libmnt_table *tb, const char *path) {
    FILE *fp = fopen(path, "r");
    if (!fp) return -1;

    char *line = NULL;
    size_t len = 0;
    while (getline(&line, &len, fp) != -1) {
        char source[4096] = {0};
        char target[4096] = {0};
        if (sscanf(line, "%4095s %4095s", source, target) == 2) {
            table_add(tb, 0, 0, source, target);
        }
    }

    free(line);
    fclose(fp);
    return 0;
}

struct libmnt_context *mnt_new_context(void) {
    return calloc(1, sizeof(struct libmnt_context));
}

void mnt_free_context(struct libmnt_context *ctx) {
    free(ctx);
}

struct libmnt_iter *mnt_new_iter(int direction) {
    (void)direction;
    return calloc(1, sizeof(struct libmnt_iter));
}

void mnt_free_iter(struct libmnt_iter *itr) {
    free(itr);
}

struct libmnt_table *mnt_new_table(void) {
    return calloc(1, sizeof(struct libmnt_table));
}

void mnt_free_table(struct libmnt_table *tb) {
    if (!tb) return;
    for (size_t i = 0; i < tb->count; i++) {
        free(tb->items[i].source);
        free(tb->items[i].target);
    }
    free(tb->items);
    free(tb);
}

int mnt_table_parse_file(struct libmnt_table *tb, const char *filename) {
    if (!tb || !filename) return -1;
    if (strstr(filename, "mountinfo")) return parse_mountinfo(tb, filename);
    return parse_mounts(tb, filename);
}

int mnt_context_get_mtab(struct libmnt_context *ctx, struct libmnt_table **tb) {
    (void)ctx;
    if (!tb) return -1;
    *tb = mnt_new_table();
    if (!*tb) return -1;
    return parse_mountinfo(*tb, "/proc/self/mountinfo");
}

int mnt_table_next_fs(struct libmnt_table *tb, struct libmnt_iter *itr, struct libmnt_fs **fs) {
    if (!tb || !itr || !fs) return 1;
    if (itr->idx >= tb->count) return 1;
    *fs = &tb->items[itr->idx++];
    return 0;
}

const char *mnt_fs_get_source(struct libmnt_fs *fs) {
    return fs ? fs->source : NULL;
}

const char *mnt_fs_get_target(struct libmnt_fs *fs) {
    return fs ? fs->target : NULL;
}

int mnt_fs_get_id(struct libmnt_fs *fs) {
    return fs ? fs->id : -1;
}

int mnt_fs_get_parent_id(struct libmnt_fs *fs) {
    return fs ? fs->parent_id : -1;
}

char *mnt_pretty_path(const char *path, void *cache) {
    (void)cache;
    return path ? strdup(path) : NULL;
}

