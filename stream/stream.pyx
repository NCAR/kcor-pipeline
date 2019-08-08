import numpy as np


def filter(unsigned short[:, :, :, :] states,
           unsigned short[:, :, :] states_mean,
           unsigned short[:, :, :] states_median,
           float threshold,
           float ss):
    corrected = np.empty((4, 1024, 1024), dtype=np.uint16)
    cdef unsigned short[:, :, :] corrected_view = corrected

    cdef int s, i, j, k
    cdef Py_ssize_t n
    cdef Py_ssize_t numsum = states.shape[3]
    states_n = np.empty(numsum, dtype=np.uint16)
    cdef unsigned short[:] states_n_view = states_n

    cdef unsigned short temp_sum

    for s in range(4):
        for i in range(1024):
            for j in range(1024):
                for k in range(numsum):
                    states_n_view[k] = states[s, i, j, k]

                ind = np.where(np.abs(states_n - states_median[s, i, j]) < ss * np.sqrt(states_median[s, i, j]))

                indices = ind[0]
                n = indices.size
                if n > threshold:
                    temp_sum = 0
                    for k in range(n):
                        temp_sum += states[s, i, j, indices[k]]
                    corrected_view[s, i, j] = temp_sum / n
                else:
                    corrected_view[s, i, j] = states_mean[s, i, j]

    return corrected
