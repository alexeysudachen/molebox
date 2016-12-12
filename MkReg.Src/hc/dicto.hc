
/*

  Copyright (C) 2011, Alexey Sudachen, https://goo.gl/lJNXya.

*/

#ifndef C_once_38B1FFE7_1462_42EB_BABE_AA8E0BE62203
#define C_once_38B1FFE7_1462_42EB_BABE_AA8E0BE62203

#ifdef _LIBYOYO
#define _YO_DICTO_BUILTIN
#endif

#include "yoyo.hc"
#include "crc.hc"
#include "buffer.hc"
#include "array.hc"
#include "string.hc"

typedef struct _YO_DICTO_REC
  {
    struct _YO_DICTO_REC *next;
    void *ptr;
    byte_t hashcode;
    char key[1];
  } YO_DICTO_REC;

typedef struct _YO_DICTO
  {
    struct _YO_DICTO_REC **table; 
    int count;
    int width;
  } YO_DICTO;


#define Dicto_Hash_1(Key) Crc_8_Of_Cstr(Key)
#define Dicto_Count(Dicto) ((int)((YO_DICTO*)(Dicto))->count+0)

void Dicto_Rehash(YO_DICTO *o);

#ifdef _YO_DICTO_BUILTIN  
int Dicto_Width_Values[] = {5,11,23,47,97,181,256};
#endif

YO_DICTO_REC **Dicto_Backet(YO_DICTO *o, byte_t hashcode, char *key)
#ifdef _YO_DICTO_BUILTIN  
  {
    YO_DICTO_REC **nrec;
    
    if ( !o->table )
      {
        o->width = Dicto_Width_Values[0];
        o->table = Yo_Malloc_Npl(o->width*sizeof(void*));
        memset(o->table,0,o->width*sizeof(void*));
      }
      
    nrec = &o->table[hashcode%o->width];
    
    while ( *nrec )
      {
        if ( hashcode == (*nrec)->hashcode && !strcmp((*nrec)->key,key) )
          break;
        nrec = &(*nrec)->next;
      }
    
    return nrec;
  }
#endif
  ;

YO_DICTO_REC *Dicto_Allocate(char *key)
#ifdef _YO_DICTO_BUILTIN  
  {
    int keylen = strlen(key);
    YO_DICTO_REC *Q = Yo_Malloc_Npl(sizeof(YO_DICTO_REC) + keylen);
    memcpy(Q->key,key,keylen+1);
    Q->hashcode = Dicto_Hash_1(key);
    Q->next = 0;
    Q->ptr = 0;
    return Q;
  }
#endif
  ;

void *Dicto_Get(YO_DICTO *o, char *key, void *dflt)
#ifdef _YO_DICTO_BUILTIN  
  {
    if ( key )
      {
        byte_t hashcode = Dicto_Hash_1(key);
        YO_DICTO_REC *Q = *Dicto_Backet(o,hashcode,key);
        if ( Q )
          return Q->ptr;
      }
    return dflt;
  }
#endif
  ;

void *Dicto_Get_Key_Ptr(YO_DICTO *o, char *key)
#ifdef _YO_DICTO_BUILTIN  
  {
    if ( key )
      {
        byte_t hashcode = Dicto_Hash_1(key);
        YO_DICTO_REC *Q = *Dicto_Backet(o,hashcode,key);
        if ( Q )
          return Q->key;
      }
    return 0;
  }
#endif
  ;

int Dicto_Has(YO_DICTO *o, char *key)
#ifdef _YO_DICTO_BUILTIN  
  {
    if ( key )
      {
        byte_t hashcode = Dicto_Hash_1(key);
        if ( *Dicto_Backet(o,hashcode,key) )
          return 1;
      }
    return 0;
  }
#endif
  ;

void *Dicto_Put(YO_DICTO *o, char *key, void *val)
#ifdef _YO_DICTO_BUILTIN  
  {
    if ( key )
      {
        byte_t hashcode = Dicto_Hash_1(key);
        YO_DICTO_REC **Q = Dicto_Backet(o,hashcode,key);
        if ( *Q )
          {
            YO_DICTO_REC *p = *Q;
            void *self = o;
            void (*destructor)(void*) = 
                               Yo_Find_Method_Of(&self
                                                ,Oj_Destruct_Element_OjMID,0);
            if ( destructor )
              (*destructor)(p->ptr);
            p->ptr = val;
            key = (*Q)->key;
          }
        else
          {
            *Q = Dicto_Allocate(key);
            key = (*Q)->key;
            (*Q)->ptr = val;
            ++o->count;
            if ( o->count > o->width*3 )
              Dicto_Rehash(o);
          }
        return key;
      }
    else
      return 0;
  }
#endif
  ;

void Dicto_Del(YO_DICTO *o, char *key)
#ifdef _YO_DICTO_BUILTIN  
  {
    if ( key )
      {
        byte_t hashcode = Dicto_Hash_1(key);
        YO_DICTO_REC **Q = Dicto_Backet(o,hashcode,key);
        if ( *Q )
          {
            YO_DICTO_REC *p = *Q;
            void *self = o;
            void (*destructor)(void*) = 
                               Yo_Find_Method_Of(&self
                                                ,Oj_Destruct_Element_OjMID,0);
            if ( destructor )
              (*destructor)(p->ptr);
            *Q = (*Q)->next;
            free(p);
            STRICT_REQUIRE ( o->count >= 1 );
            --o->count;
          }
      }
  }
#endif
  ;

/* returns unmanaged value */
void *Dicto_Take_Npl(YO_DICTO *o, char *key)
#ifdef _YO_DICTO_BUILTIN  
  {
    if ( key )
      {
        byte_t hashcode = Dicto_Hash_1(key);
        YO_DICTO_REC **Q = Dicto_Backet(o,hashcode,key);
        if ( *Q )
          {
            YO_DICTO_REC *p = *Q;
            void *ret = p->ptr;
            *Q = (*Q)->next;
            free(p);
            STRICT_REQUIRE ( o->count >= 1 );
            --o->count;
            return ret;
          }
      }
    return 0;
  }
#endif
  ;

void *Dicto_Take(YO_DICTO *o, char *key)
#ifdef _YO_ARRAY_BUILTIN
  {
    void *self = o;
    void (*destruct)(void *) = Yo_Find_Method_Of(&self
                                                ,Oj_Destruct_Element_OjMID
                                                ,YO_RAISE_ERROR);
    void *Q = Dicto_Take_Npl(o,key);
    
    if ( Q )
      Yo_Pool_Ptr(Q,destruct);
      
    return Q;
  }
#endif
  ;

void Dicto_Clear(YO_DICTO *o)
#ifdef _YO_DICTO_BUILTIN  
  {
    int i;
    void *self = o;
    void (*destructor)(void*) = Yo_Find_Method_Of(&self
                                                 ,Oj_Destruct_Element_OjMID,0);
    
    if ( o->table )
      for ( i = 0; i < o->width; ++i )
        while ( o->table[i] )
          {
            YO_DICTO_REC *Q = o->table[i];
            o->table[i] = Q->next;
            if ( destructor )
              (*destructor)(Q->ptr);
            free(Q);
          }

    if ( o->table ) free( o->table );
    o->table = 0;
    o->width = 0;
    o->count = 0;      
  }
#endif
  ;

#ifdef _YO_DICTO_BUILTIN  
void Dicto_Rehash(YO_DICTO *o)
  {
    if ( o->table && o->count )
      {
        int i;
        int width = 256;
        YO_DICTO_REC **table;
        
        for ( i = 0; Dicto_Width_Values[i] < 256; ++i )
          if ( o->count <= Dicto_Width_Values[i] + Dicto_Width_Values[i]/2  )
            {
              width = Dicto_Width_Values[i]; 
              break;
            }
        
        if ( width > o->width ) 
          {
            table = Yo_Malloc_Npl(width*sizeof(void*));
            memset(table,0,width*sizeof(void*));
        
            for ( i = 0; i < o->width; ++i )
              while ( o->table[i] )
                {
                  YO_DICTO_REC *Q = o->table[i];
                  o->table[i] = Q->next;
                  Q->next = table[Q->hashcode%width];
                  table[Q->hashcode%width] = Q;
                }
      
            free(o->table);
            o->width = width;
            o->table = table;    
          }
      }
  }
#endif
  ;

void Dicto_Destruct(YO_DICTO *o)
#ifdef _YO_DICTO_BUILTIN  
  {
    Dicto_Clear(o);
    Yo_Object_Destruct(o);
  }
#endif
  ;

void *Dicto_Refs(void)
#ifdef _YO_DICTO_BUILTIN  
  {
    static YO_FUNCTABLE funcs[] = 
      { {0},
        {Oj_Destruct_OjMID, Dicto_Destruct},
        {Oj_Destruct_Element_OjMID, Yo_Unrefe},
        {0}};
    YO_DICTO *dicto = Yo_Object(sizeof(YO_DICTO),funcs);
    return dicto;
  }
#endif
  ;

void *Dicto_Ptrs(void)
#ifdef _YO_DICTO_BUILTIN  
  {
    static YO_FUNCTABLE funcs[] = 
      { {0},
        {Oj_Destruct_OjMID, Dicto_Destruct},
        {Oj_Destruct_Element_OjMID, free},
        {0}};
    YO_DICTO *dicto = Yo_Object(sizeof(YO_DICTO),funcs);
    return dicto;
  }
#endif
  ;

void *Dicto_Init(void)
#ifdef _YO_DICTO_BUILTIN  
  {
    YO_DICTO *dicto = Yo_Object_Dtor(sizeof(YO_DICTO),Dicto_Destruct);
    return dicto;
  }
#endif
  ;

typedef void (*dicto_apply_filter_t)(char *,void *,void *);

void Dicto_Apply(YO_DICTO *o
                , /*dicto_apply_filter_t*/ void *_filter
                , void *state)  
#ifdef _YO_DICTO_BUILTIN  
  {
    int i;
    YO_DICTO_REC *nrec;
    dicto_apply_filter_t filter = _filter;
    if ( o && o->table ) 
      for ( i = 0; i < o->width; ++i )
        {      
          nrec = o->table[i];
          while ( nrec )
            {
              __Auto_Release filter(nrec->key,nrec->ptr,state);
              nrec = nrec->next;
            }  
        }
  }
#endif
  ;

void _Dicto_Filter_Push_Value(char *key, void *value, YO_ARRAY *a)
#ifdef _YO_DICTO_BUILTIN  
  {
    Array_Push(a,value);
  }
#endif
  ;
    
YO_ARRAY *Dicto_Values(YO_DICTO *o)
#ifdef _YO_DICTO_BUILTIN  
  {
    YO_ARRAY *a = Array_Void();
    Dicto_Apply(o,(dicto_apply_filter_t)_Dicto_Filter_Push_Value,a);
    return a;
  }
#endif
  ;
    
void _Dicto_Filter_Push_Key(char *key, void *value, YO_ARRAY *a)
#ifdef _YO_DICTO_BUILTIN  
  {
    Array_Push(a,key);
  }
#endif
  ;
    
YO_ARRAY *Dicto_Keys(YO_DICTO *o)
#ifdef _YO_DICTO_BUILTIN  
  {
    YO_ARRAY *a = Array_Void();
    Dicto_Apply(o,(dicto_apply_filter_t)_Dicto_Filter_Push_Key,a);
    return a;
  }
#endif
  ;
  
typedef void (*dicto_format_printer_t)(YO_BUFFER *bf,void *S);

char *Dicto_Format(YO_DICTO *o
                  , /*dicto_format_printer_t*/ void *_print
                  , YO_BUFFER *_bf, int pretty)
#ifdef _YO_DICTO_BUILTIN  
  {
    int start = 0, i, j=0;
    YO_BUFFER *bf = _bf;
    YO_DICTO_REC *nrec;
    dicto_format_printer_t print = _print;

    if ( !bf ) bf = Buffer_Init(0);
    start = bf->count;
    
    Buffer_Fill_Append(bf,'{',1);
    if ( pretty )
      Buffer_Fill_Append(bf,'\n',1); 

    if ( o && o->table ) 
      for ( i = 0; i < o->width; ++i )
        {      
          nrec = o->table[i];
          while ( nrec )
            {
              if ( j ) 
                if ( pretty )
                  Buffer_Fill_Append(bf,'\n',1); 
                else 
                  Buffer_Append(bf,", ",2); 
              else 
                j = 1; 
              if ( pretty )
                Buffer_Fill_Append(bf,' ',2); 
              Buffer_Append(bf,nrec->key,-1);
              Buffer_Append(bf,": ",2);
              __Auto_Release print(bf,nrec->ptr);
              nrec = nrec->next;
            }  
        }
    
    if ( j && pretty )
      Buffer_Fill_Append(bf,'\n',1); 
    Buffer_Fill_Append(bf,'}',1);

    if ( !_bf )
      return Buffer_Take_Data(bf);
    else
      return bf->at+start;
  }
#endif
  ;

YO_DICTO *Dicto_Set_Str(YO_DICTO *dicto, char *key, void *val)
#ifdef _YO_DICTO_BUILTIN  
  {
    if ( !dicto )
      dicto = Dicto_Ptrs();
    Dicto_Put(dicto,key,Str_Copy_Npl(val,-1));
    return dicto; 
  }
#endif
  ;
  
#endif /* C_once_38B1FFE7_1462_42EB_BABE_AA8E0BE62203 */

