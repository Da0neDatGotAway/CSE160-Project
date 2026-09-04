#ifndef CLANGD_NESC_MACROS_H
#define CLANGD_NESC_MACROS_H

// 1. Force standard C types into the global scope
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// 2. Core implementation and concurrency fixes
#define implementation static void __nesc_implementation(void)
#define atomic if(1)

// 3. Structural encapsulation mapping
#define module struct
#define configuration struct
#define interface struct

// 4. Component linking keywords
#define provides
#define uses
#define components
#define new
#define as *

// 5. nesC function modifiers
#define command
#define event
#define task
#define async
#define norace

// 6. nesC action keywords
#define call
#define post
#define signal

// 7. Network struct and integer type aliases
#define nx_struct struct
#define nx_union union
#define nx_int8_t int8_t
#define nx_uint8_t uint8_t
#define nx_int16_t int16_t
#define nx_uint16_t uint16_t
#define nx_int32_t int32_t
#define nx_uint32_t uint32_t
#define nx_int64_t int64_t
#define nx_uint64_t uint64_t
#define nxle_uint16_t uint16_t
#define nxle_uint32_t uint32_t
#define nxle_uint64_t uint64_t

// 8. Fallback TinyOS system types (in case tos/types paths fail)
#ifndef SUCCESS
#define SUCCESS 0
#define FAIL 1
#endif
typedef uint8_t error_t;
typedef struct message_t message_t;

#endif // CLANGD_NESC_MACROS_H