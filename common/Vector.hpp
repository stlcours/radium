
#ifndef RADIUM_COMMON_VECTOR_HPP
#define RADIUM_COMMON_VECTOR_HPP

#include "validatemem_proc.h"

#include "LockAsserter.hpp"

/**
 *
 * radium::Vector validates multithreaded access and have special support for adding elements when called from a realtime thread.
 *
 **/


extern bool g_qtgui_has_stopped;


// NOTE: Can not use radium::Vector if any of the fields in T uses a custom copy constructor (is there any way to detect that before getting a random crash?)


namespace radium{

template <typename T> struct Vector{
  
private:
  int num_elements_max;
  int num_elements;
  
  T *next_elements;
  
  T *elements_ready_for_freeing;
  
  int next_num_elements_max;
  
  LockAsserter lockAsserter;

  
  // Normally it would be a typo or an error if trying to copy a radium::Vector.
  Vector(const Vector&) = delete;
  Vector& operator=(const Vector&) = delete;

  
public:
  
  T *elements;
  
  Vector()
    : num_elements_max(4)
    , num_elements(0)
    , next_elements(NULL)
    , elements_ready_for_freeing(NULL)
    , next_num_elements_max(0)
  {
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);

    R_ASSERT(num_elements_max > 0);
    
    elements = (T*)V_calloc(num_elements_max, sizeof(T));
  }

  ~Vector(){
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);

    // Don't want to free static global memory during shut down since it may be used by threads which are not shut down. (hmm, this will probably cover bugs)
    if (g_qtgui_has_stopped==false){
      V_free(elements);      
      elements = NULL; // For debugging
    }
  }

  // This function can be called in parallell with the other const functions (i.e. the non-mutating ones).
  T operator[](int i) const {
    return at(i);
  }

  T at(int i) const {
    LOCKASSERTER_SHARED(&lockAsserter);

    R_ASSERT(i>=0);
    R_ASSERT(i<num_elements);
    
    return elements[i];
  }

  T* ref(int i) const {
    LOCKASSERTER_SHARED(&lockAsserter);

    R_ASSERT(i>=0);
    R_ASSERT(i<num_elements);
    
    return &elements[i];
  }

  // This function can be called in parallell with the other const functions (i.e. the non-mutating ones).
  const T* begin() const {
    LOCKASSERTER_SHARED(&lockAsserter);
    
    return &elements[0];
  }

  // This function can be called in parallell with the other const functions (i.e. the non-mutating ones).
  const T* end() const {
    LOCKASSERTER_SHARED(&lockAsserter);
    
    return &elements[num_elements];
  }

  // This function can be called in parallell with the other const functions (i.e. the non-mutating ones).
  bool is_empty(void) const {
    LOCKASSERTER_SHARED(&lockAsserter);
    
    return num_elements == 0;
  }

  // This function can be called in parallell with the other const functions (i.e. the non-mutating ones).
  int size(void) const {
    LOCKASSERTER_SHARED(&lockAsserter);
    
    return num_elements;
  }

  // NOT RT safe
  //
  // This function must _always or never_ be called before calling add. No mixing.
  //
  // This function CAN be called in parallell with the const functions (i.e. the non-mutating ones),
  // but it can not be called in parallel with itself or any other non-const/mutating function.
  // (it is not asserted that this function is not called in parallell with itself)
  //
  // post_add MUST be called after calling add after calling ensure_there_is_room_for_more_without_having_to_allocate_memory.
  void ensure_there_is_room_for_more_without_having_to_allocate_memory(int how_many = 1){
    LOCKASSERTER_SHARED(&lockAsserter);

    R_ASSERT(elements_ready_for_freeing == NULL);
    R_ASSERT(next_elements == NULL);

    int new_num_elements = num_elements + how_many;

    R_ASSERT(num_elements_max > 0);
      
    if (new_num_elements > num_elements_max) {

      next_num_elements_max = num_elements_max;
      
      while (new_num_elements > next_num_elements_max)
        next_num_elements_max *= 2;

      next_elements = (T*) V_calloc(sizeof(T), next_num_elements_max);
      memcpy(next_elements, elements, sizeof(T)*num_elements);      
    }
  }

  void ensure_there_is_room_for_more_at_least_n_without_having_to_allocate_memory(int n){
    ensure_there_is_room_for_more_without_having_to_allocate_memory(n - num_elements);
  }
    
  // Must be called after calling 'add' if 'ensure_there_is_room_for_one_more_without_having_to_allocate_memory' was called before 'add'.
  void post_add(void){
    LOCKASSERTER_SHARED(&lockAsserter);
    
    if (elements_ready_for_freeing != NULL){
      V_free(elements_ready_for_freeing);
      elements_ready_for_freeing = NULL;
    }
  }
  
private:
    
    void basic_add(T t){
      num_elements++;

      R_ASSERT(num_elements_max > 0);

      if (num_elements > num_elements_max) {        
        while (num_elements > num_elements_max)
          num_elements_max *= 2;

        R_ASSERT_NON_RELEASE(!PLAYER_current_thread_has_lock()); // V_realloc should already have an assert for this, but the memory functions are a bit chaotic.

        elements = (T*) V_realloc(elements, sizeof(T) * num_elements_max);
      }
      
      elements[num_elements-1] = t;
    }

  void remove_pos_internal(int pos, bool keep_order){
    R_ASSERT_RETURN_IF_FALSE(pos < num_elements);


    if (keep_order) {
      
      int i;
      this->num_elements--;
      
      for(i=pos;i<this->num_elements;i++)
        this->elements[i]=this->elements[i+1];
      
    } else {

      if (num_elements==1){
        R_ASSERT(pos==0);
      } else {
        elements[pos] = elements[num_elements-1];
      }
      
      num_elements--;
    }

    memset(&elements[num_elements], 0, sizeof(T)); // for debugging
  }

  int find_pos_internal(const T t) const {
    int pos;
    
    for(pos=0 ; pos<num_elements ; pos++)
      if (elements[pos]==t)
        break;

    if (pos<num_elements)
      return pos;
    else
      return -1;
  }

public:
  
  // Only RT safe if ensure_there_is_room_for_one_more_without_having_to_allocate_memory is called first AND post_add is called afterwards.
  //
  // This function can NOT be called in parallell with other functions
  //
  void push_back(T t){
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);

    //R_ASSERT(elements_ready_for_freeing == NULL); <-- Fails when we have preallocated for more than one element.

    if (next_elements == NULL) {

      basic_add(t);
      
    } else {

      num_elements++;

      R_ASSERT(num_elements <= next_num_elements_max);

      elements_ready_for_freeing = elements;
      
      elements = next_elements;
      num_elements_max = next_num_elements_max;
      
      next_elements = NULL;
      next_num_elements_max = 0;

      elements[num_elements-1] = t;
    }
  }

  // NOT RT safe
  //
  // This function can NOT be called in parallell with other functions
  void append(Vector<T> *ts){
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);
    
    R_ASSERT(next_elements == NULL);

    for (T t : *ts)
      basic_add(t);
  }

  // NOT RT safe
  //
  // This function can NOT be called in parallell with other functions
  void append(Vector<T> &ts){
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);
    
    R_ASSERT(next_elements == NULL);
    
    for (T t : ts)
      basic_add(t);
  }

  Vector<T> intersection(const Vector<T> &ts) const {
    Vector<T> ret;
    
    for (const T &t : ts)
      if (contains(t))
        ret.push_back(ret);

    return ret;
  }
  
  bool intersects(const Vector<T> &ts) const {
    for (const T &t : ts)
      if (contains(t))
        return true;

    return false;
  }

  bool intersects(const Vector<T> &ts, bool (*equal)(const T, const T)) const {
    for (const T &t1 : ts)
      for(int i = 0 ; i < num_elements ; i++)
        if (equal(elements[i], t1))
          return true;

    return false;
  }

  bool only_unique_elements(bool (*equal)(const T, const T)) const {
    for(int i1 = 0 ; i1 < num_elements-1 ; i1++)
      for(int i2 = i1+1 ; i2 < num_elements ; i2++){
        printf("i1: %d, i2: %d\n", i1, i2);
        if (equal(elements[i1], elements[i2]))
          return false;
      }

    return true;
  }
  
  // This function can be called in parallell with the other const functions (i.e. the non-mutating ones).
  int find_pos(const T t) const {
    LOCKASSERTER_SHARED(&lockAsserter);

    return find_pos_internal(t);
  }

  bool contains(const T t) const {
    return find_pos(t) >= 0;
  }
    
  // RT safe (except for the O(n) performance)
  //
  // This function can NOT be called in parallell with other functions
  void remove(const T t, bool keep_order = false){
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);
    
    R_ASSERT(next_elements == NULL);
    R_ASSERT(elements_ready_for_freeing == NULL);

    int pos = find_pos_internal(t);
    R_ASSERT_RETURN_IF_FALSE(pos>=0);
    
    remove_pos_internal(pos, keep_order);
  }

  // RT safe (except for the O(n) performance)
  //
  // This function can NOT be called in parallell with other functions
  void remove_pos(int pos, bool keep_order = false){
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);

    remove_pos_internal(pos, keep_order);
  }

  T pop(int pos, bool keep_order = false){
    T ret = at(pos);
    remove_pos(pos, keep_order);
    return ret;
  }

  template <class S>
  void sort(S comp){
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);
    
    std::sort(&elements[0], &elements[num_elements], comp);
  }
  
  // RT safe
  //
  // This function can NOT be called in parallell with other functions
  void clear(void) {
    LOCKASSERTER_EXCLUSIVE(&lockAsserter);

    R_ASSERT(next_elements == NULL);
    num_elements = 0;
  }

};






}


#endif
