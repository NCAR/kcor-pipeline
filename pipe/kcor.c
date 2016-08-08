#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#ifdef strlcpy
#undef strlcpy
#endif

#ifdef strlcat
#undef strlcat
#endif

#include "idl_export.h"

#define IDL_KCOR_MATRIX_VECTOR_MULTIPLY(TYPE)                                \
void IDL_kcor_matrix_vector_multiply_ ## TYPE(TYPE *a_data, TYPE *b_data, TYPE *result_data, int n, int m) { \
  int row, col;                                                              \
  for (row = 0; row < m; row++) {                                            \
    for (col = 0; col < n; col++) {                                          \
      result_data[row] += a_data[row * n + col] * b_data[col];               \
    }                                                                        \
  }                                                                          \
}

IDL_KCOR_MATRIX_VECTOR_MULTIPLY(UCHAR)
IDL_KCOR_MATRIX_VECTOR_MULTIPLY(IDL_INT)
IDL_KCOR_MATRIX_VECTOR_MULTIPLY(IDL_LONG)
IDL_KCOR_MATRIX_VECTOR_MULTIPLY(float)
IDL_KCOR_MATRIX_VECTOR_MULTIPLY(double)
IDL_KCOR_MATRIX_VECTOR_MULTIPLY(IDL_UINT)
IDL_KCOR_MATRIX_VECTOR_MULTIPLY(IDL_ULONG)
IDL_KCOR_MATRIX_VECTOR_MULTIPLY(IDL_LONG64)
IDL_KCOR_MATRIX_VECTOR_MULTIPLY(IDL_ULONG64)

#define IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(TYPE, IDL_TYPE) \
IDL_VPTR IDL_kcor_batch_matrix_vector_multiply_ ## TYPE(IDL_VPTR a, IDL_VPTR b, int n, int m, int n_multiplies) { \
  IDL_VPTR result; \
  int i; \
  IDL_MEMINT dims[] = { m, n_multiplies }; \
  TYPE *result_data = (TYPE *) IDL_MakeTempArray(IDL_TYPE, 2, dims, IDL_ARR_INI_ZERO, &result); \
  TYPE *a_data = (TYPE *)a->value.arr->data; \
  TYPE *b_data = (TYPE *)b->value.arr->data; \
  for (i = 0; i < n_multiplies; i++) { \
    IDL_kcor_matrix_vector_multiply_ ## TYPE(a_data + n * m * i, \
                                             b_data + n * i, \
                                             result_data + m * i, \
                                             n, m); \
  } \
  return result; \
}

IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(UCHAR, IDL_TYP_BYTE)
IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(IDL_INT, IDL_TYP_INT)
IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(IDL_LONG, IDL_TYP_LONG)
IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(float, IDL_TYP_FLOAT)
IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(double, IDL_TYP_DOUBLE)
IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(IDL_UINT, IDL_TYP_UINT)
IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(IDL_ULONG, IDL_TYP_ULONG)
IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(IDL_LONG64, IDL_TYP_LONG64)
IDL_KCOR_BATCH_MATRIX_VECTOR_MULTIPLY(IDL_ULONG64, IDL_TYP_ULONG64)

static IDL_VPTR IDL_kcor_batched_matrix_vector_multiply(int argc, IDL_VPTR *argv) {
  IDL_VPTR a = argv[0];
  IDL_VPTR b = argv[1];
  IDL_LONG n = IDL_LongScalar(argv[2]);
  IDL_LONG m = IDL_LongScalar(argv[3]);
  IDL_LONG n_multiplies = IDL_LongScalar(argv[4]);
  IDL_VPTR result;

  switch (a->type) {
    case IDL_TYP_BYTE:
      result = IDL_kcor_batch_matrix_vector_multiply_UCHAR(a, b, n, m, n_multiplies);
      break;
    case IDL_TYP_INT:
      result = IDL_kcor_batch_matrix_vector_multiply_IDL_INT(a, b, n, m, n_multiplies);
      break;
    case IDL_TYP_LONG:
      result = IDL_kcor_batch_matrix_vector_multiply_IDL_LONG(a, b, n, m, n_multiplies);
      break;
    case IDL_TYP_FLOAT:
      result = IDL_kcor_batch_matrix_vector_multiply_float(a, b, n, m, n_multiplies);
      break;
    case IDL_TYP_DOUBLE:
      result = IDL_kcor_batch_matrix_vector_multiply_double(a, b, n, m, n_multiplies);
      break;
    case IDL_TYP_UINT:
      result = IDL_kcor_batch_matrix_vector_multiply_IDL_UINT(a, b, n, m, n_multiplies);
      break;
    case IDL_TYP_ULONG:
      result = IDL_kcor_batch_matrix_vector_multiply_IDL_ULONG(a, b, n, m, n_multiplies);
      break;
    case IDL_TYP_LONG64:
      result = IDL_kcor_batch_matrix_vector_multiply_IDL_LONG64(a, b, n, m, n_multiplies);
      break;
    case IDL_TYP_ULONG64:
      result = IDL_kcor_batch_matrix_vector_multiply_IDL_ULONG64(a, b, n, m, n_multiplies);
      break;
    default:
      IDL_Message(IDL_M_NAMED_GENERIC, IDL_MSG_LONGJMP, "unsupported type");
      break;
  }
  
  return result;
}


int IDL_Load(void) {
  /*
   * These tables contain information on the functions and procedures
   * that make up the KCOR DLM. The information contained in these
   * tables must be identical to that contained in kcor.dlm.
   */
  static IDL_SYSFUN_DEF2 function_addr[] = {
    { IDL_kcor_batched_matrix_vector_multiply, "KCOR_BATCHED_MATRIX_VECTOR_MULTIPLY", 5, 5, 0, 0 },

  };

  /*
   * Register our routines. The routines must be specified exactly the same
   * as in kcor.
   */
  return IDL_SysRtnAdd(function_addr, TRUE, IDL_CARRAY_ELTS(function_addr));
}
