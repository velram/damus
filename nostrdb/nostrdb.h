#ifndef NOSTRDB_H
#define NOSTRDB_H

#include <inttypes.h>
#include "cursor.h"

struct ndb_str {
	unsigned char flag;
	union {
		const char *str;
		unsigned char *id;
	};
};

struct ndb_keypair {
	unsigned char pubkey[32];
	unsigned char secret[32];
	unsigned char pair[96];
};

// these must be byte-aligned, they are directly accessing the serialized data
// representation
#pragma pack(push, 1)

/// We can store byte data in the string table, so 
#define NDB_PACKED_STR     0x1
#define NDB_PACKED_ID      0x2

union ndb_packed_str {
	struct {
		char str[3];
		// we assume little endian everywhere. sorry not sorry.
		unsigned char flag; // NDB_PACKED_STR, etc
	} packed;

	uint32_t offset;
	unsigned char bytes[4];
};

struct ndb_tag {
	uint16_t count;
	union ndb_packed_str strs[0];
};

struct ndb_tags {
	uint16_t count;
	struct ndb_tag tag[0];
};

// v1
struct ndb_note {
	unsigned char version;    // v=1
	unsigned char padding[3]; // keep things aligned
	unsigned char id[32];
	unsigned char pubkey[32];
	unsigned char sig[64];

	uint32_t created_at;
	uint32_t kind;
	uint32_t content_length;
	union ndb_packed_str content;
	uint32_t strings;

	// nothing can come after tags since it contains variadic data
	struct ndb_tags tags;
};

#pragma pack(pop)

struct ndb_builder {
	struct cursor mem;
	struct cursor note_cur;
	struct cursor strings;
	struct cursor str_indices;
	struct ndb_note *note;
	struct ndb_tag *current_tag;
};

struct ndb_iterator {
	struct ndb_note *note;
	struct ndb_tag *tag;

	// current outer index
	int index;
};

// HELPERS
int ndb_calculate_id(struct ndb_note *note, unsigned char *buf, int buflen);
int ndb_sign_id(struct ndb_keypair *keypair, unsigned char id[32], unsigned char sig[64]);
int ndb_create_keypair(struct ndb_keypair *key);
int ndb_decode_key(const char *secstr, struct ndb_keypair *keypair);

// BUILDER
int ndb_note_from_json(const char *json, int len, struct ndb_note **, unsigned char *buf, int buflen);
int ndb_builder_init(struct ndb_builder *builder, unsigned char *buf, int bufsize);
int ndb_builder_finalize(struct ndb_builder *builder, struct ndb_note **note, struct ndb_keypair *privkey);
int ndb_builder_set_content(struct ndb_builder *builder, const char *content, int len);
void ndb_builder_set_created_at(struct ndb_builder *builder, uint32_t created_at);
void ndb_builder_set_sig(struct ndb_builder *builder, unsigned char *sig);
void ndb_builder_set_pubkey(struct ndb_builder *builder, unsigned char *pubkey);
void ndb_builder_set_id(struct ndb_builder *builder, unsigned char *id);
void ndb_builder_set_kind(struct ndb_builder *builder, uint32_t kind);
int ndb_builder_new_tag(struct ndb_builder *builder);
int ndb_builder_push_tag_str(struct ndb_builder *builder, const char *str, int len);

static inline struct ndb_str ndb_note_str(struct ndb_note *note,
					  union ndb_packed_str *pstr)
{
	struct ndb_str str;
	str.flag = pstr->packed.flag;

	if (str.flag == NDB_PACKED_STR) {
		str.str = pstr->packed.str;
		return str;
	}

	str.str = ((const char *)note) + note->strings + (pstr->offset & 0xFFFFFF);
	return str;
}

static inline struct ndb_str ndb_tag_str(struct ndb_note *note,
					 struct ndb_tag *tag, int ind)
{
	return ndb_note_str(note, &tag->strs[ind]);
}

static inline struct ndb_str ndb_iter_tag_str(struct ndb_iterator *iter,
					      int ind)
{
	return ndb_tag_str(iter->note, iter->tag, ind);
}

static inline unsigned char * ndb_note_id(struct ndb_note *note)
{
	return note->id;
}

static inline unsigned char * ndb_note_pubkey(struct ndb_note *note)
{
	return note->pubkey;
}

static inline unsigned char * ndb_note_sig(struct ndb_note *note)
{
	return note->sig;
}

static inline uint32_t ndb_note_created_at(struct ndb_note *note)
{
	return note->created_at;
}

static inline uint32_t ndb_note_kind(struct ndb_note *note)
{
	return note->kind;
}

static inline const char *ndb_note_content(struct ndb_note *note)
{
	return ndb_note_str(note, &note->content).str;
}

static inline uint32_t ndb_note_content_length(struct ndb_note *note)
{
	return note->content_length;
}

static inline struct ndb_note * ndb_note_from_bytes(unsigned char *bytes)
{
	struct ndb_note *note = (struct ndb_note *)bytes;
	if (note->version != 1)
		return 0;
	return note;
}

static inline union ndb_packed_str ndb_offset_str(uint32_t offset)
{
	// ensure accidents like -1 don't corrupt our packed_str
	union ndb_packed_str str;
	// most significant byte is reserved for ndb_packtype
	str.offset = offset & 0xFFFFFF;
	return str;
}

static inline union ndb_packed_str ndb_char_to_packed_str(char c)
{
	union ndb_packed_str str;
	str.packed.flag = NDB_PACKED_STR;
	str.packed.str[0] = c;
	str.packed.str[1] = '\0';
	return str;
}

static inline union ndb_packed_str ndb_chars_to_packed_str(char c1, char c2)
{
	union ndb_packed_str str;
	str.packed.flag = NDB_PACKED_STR;
	str.packed.str[0] = c1;
	str.packed.str[1] = c2;
	str.packed.str[2] = '\0';
	return str;
}

static inline void ndb_tags_iterate_start(struct ndb_note *note,
					  struct ndb_iterator *iter)
{
	iter->note = note;
	iter->tag = NULL;
	iter->index = -1;
}

static inline int ndb_tags_iterate_next(struct ndb_iterator *iter)
{
	if (iter->tag == NULL || iter->index == -1) {
		iter->tag = iter->note->tags.tag;
		iter->index = 0;
		return iter->note->tags.count != 0;
	}

	struct ndb_tags *tags = &iter->note->tags;

	if (++iter->index < tags->count) {
		uint32_t tag_data_size = iter->tag->count * sizeof(iter->tag->strs[0]);
		iter->tag = (struct ndb_tag *)(iter->tag->strs[0].bytes + tag_data_size);
		return 1;
	}

	return 0;
}

#endif
