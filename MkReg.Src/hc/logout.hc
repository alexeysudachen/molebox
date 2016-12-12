
/*

  Copyright (C) 2011, Alexey Sudachen, https://goo.gl/lJNXya.

*/

#ifndef C_once_9629B105_86D6_4BF5_BAA2_62AB1ACE54EC
#define C_once_9629B105_86D6_4BF5_BAA2_62AB1ACE54EC

#ifdef _LIBYOYO
#define _YO_LOGOUT_BUILTIN
#endif

#include "yoyo.hc"
#include "file.hc"

enum 
  {
    YO_LOG_ERROR   = 0,
    YO_LOG_WARN    = 10,
    YO_LOG_INFO    = 20,
    YO_LOG_DEBUG   = 50,
    YO_LOG_ALL     = 100,
  };

#ifdef _YO_LOGOUT_BUILTIN
static clock_t YO_Log_Clock = 0;
static int YO_Log_Line_No = 0;
static int YO_Log_Fd = -1;
static int YO_Log_Opt = 0;
int YO_Log_Level = YO_LOG_INFO;
/* static int YO_Log_Pid = 0; */
#else
int YO_Log_Level;
#endif

enum
  {
    YO_LOG_DATESTAMP = 1 << 16,
    YO_LOG_PID       = 1 << 17,
    YO_LOG_DATEMARK  = 1 << 18,
    YO_LOG_LINENO    = 1 << 19,
    YO_LOG_LEVEL     = 1 << 20,
  };
  
void Close_Log()
#ifdef _YO_LOGOUT_BUILTIN  
  {
    if ( YO_Log_Fd >= 0 )
      {
        close(YO_Log_Fd);
        YO_Log_Fd = -1;
      }
  }
#endif
  ;
  
void Append_Log(char *logname, int opt)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    Close_Log();
    Create_Required_Dirs(logname);
    YO_Log_Fd = Open_File_Raise(logname,O_CREAT|O_APPEND|O_WRONLY);
    YO_Log_Opt = opt;
    YO_Log_Level = opt & 0x0ff;
  }
#endif
  ;
  
void Rewrite_Log(char *logname, int opt)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    Close_Log();
    Create_Required_Dirs(logname);
    YO_Log_Fd = Open_File_Raise(logname,O_CREAT|O_APPEND|O_WRONLY|O_TRUNC);
    YO_Log_Opt = opt;
    YO_Log_Level = opt & 0x0ff;
  }
#endif
  ;
  
void Set_Logout_Opt(int opt)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    YO_Log_Opt = opt;
    YO_Log_Level = opt & 0x0ff;
  }
#endif
  ;

#define Log_Level(L) (YO_Log_Level<L)

void Logout(int level, char *text)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    if ( level <= YO_Log_Level )
      __Xchg_Interlock
        {        
          int log_fd = YO_Log_Fd >= 0 ? YO_Log_Fd : fileno(stderr);
          char mark[80] = {0};
          int len = strlen(text);
          if ( YO_Log_Opt & YO_LOG_DATESTAMP )
            {
              clock_t t = clock();
              if ( t - YO_Log_Clock > CLOCKS_PER_SEC )
                {
                  YO_Log_Clock = t;
                  sprintf(mark, "%%clocks%% %.3f\n",(double)YO_Log_Clock/CLOCKS_PER_SEC);
                  Write_Out(log_fd,mark,strlen(mark));
                }
            }
          if ( YO_Log_Opt & (YO_LOG_LEVEL) )
            {
              if ( level == YO_LOG_ERROR )
                Write_Out(log_fd,"{error} ",8);
              else if ( level == YO_LOG_WARN )
                Write_Out(log_fd,"{warn!} ",8);
              else if ( level == YO_LOG_INFO )
                Write_Out(log_fd,"{info!} ",8);
              else
                Write_Out(log_fd,"{debug} ",8);
            }
          if ( YO_Log_Opt & (YO_LOG_DATEMARK|YO_LOG_PID|YO_LOG_LINENO) )
            {
              int i = 1;
              mark[0] = '[';
              if ( YO_Log_Opt & YO_LOG_LINENO )
                i += sprintf(mark+i,"%4d",YO_Log_Line_No);
              if ( YO_Log_Opt & YO_LOG_PID ) 
                {
                  int YO_Log_Pid = getpid();
                  if ( i > 1 ) mark[i++] = ':';
                  i += sprintf(mark+i,"%5d",YO_Log_Pid);
                }
              if ( YO_Log_Opt & YO_LOG_DATEMARK ) 
                {
                  time_t t = time(0);
                  struct tm *tm = localtime(&t);
                  if ( i > 1 ) mark[i++] = ':';
                  i += sprintf(mark+i,"%02d%02d%02d/%02d:%02d",
                          tm->tm_mday,tm->tm_mon+1,(tm->tm_year+1900)%100,
                          tm->tm_hour,tm->tm_min);
                }
              mark[i++] = ']';
              mark[i++] = ' ';
              mark[i] = 0;  
              Write_Out(log_fd,mark,i);
            }
          ++YO_Log_Line_No;
          Write_Out(log_fd,text,len);
          if ( !len || text[len-1] != '\n' )
            Write_Out(log_fd,"\n",1);
        }
  }
#endif
  ;
  
void Logoutf(int level, char *fmt, ...)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    if ( level <= YO_Log_Level )
      {
        va_list va;
        char *text;
        va_start(va,fmt);
        text = Yo_Format_(fmt,va);
        Logout(level,text);
        free(text);
        va_end(va);
      }
  }
#endif
  ;

#define Logout_Debug(S) if (YO_Log_Level<YO_LOG_DEBUG); else Logout(YO_LOG_DEBUG,S)
#define Log_Debug if (YO_Log_Level<YO_LOG_DEBUG); else Log_Debug_
void Log_Debug_(char *fmt, ...)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    va_list va;
    char *text;
    va_start(va,fmt);
    text = Yo_Format_(fmt,va);
    Logout(YO_LOG_DEBUG,text);
    free(text);
    va_end(va);
  }
#endif
  ;


#define Logout_Info(S) if (YO_Log_Level<YO_LOG_INFO); else Logout(YO_LOG_INFO,S)
#define Log_Info if (YO_Log_Level<YO_LOG_INFO); else Log_Info_
void Log_Info_(char *fmt, ...)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    va_list va;
    char *text;
    va_start(va,fmt);
    text = Yo_Format_(fmt,va);
    Logout(YO_LOG_INFO,text);
    free(text);
    va_end(va);
  }
#endif
  ;

#define Logout_Warning(S) if (YO_Log_Level<YO_LOG_WARN); else Logout(YO_LOG_WARN,S)
#define Log_Warning if (YO_Log_Level<YO_LOG_WARN); else Log_Warning_
void Log_Warning_(char *fmt, ...)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    va_list va;
    char *text;
    va_start(va,fmt);
    text = Yo_Format_(fmt,va);
    Logout(YO_LOG_WARN,text);
    free(text);
    va_end(va);
  }
#endif
  ;

#define Logout_Error(S) if (YO_Log_Level<YO_LOG_ERROR); else Logout(YO_LOG_ERROR,S)
/*#define Log_Error if (YO_Log_Level<YO_LOG_ERROR); else Log_Error_*/
void Log_Error(char *fmt, ...)
#ifdef _YO_LOGOUT_BUILTIN  
  {
    va_list va;
    char *text;
    va_start(va,fmt);
    text = Yo_Format_(fmt,va);
    Logout(YO_LOG_ERROR,text);
    free(text);
    va_end(va);
  }
#endif
  ;

#endif /* C_once_9629B105_86D6_4BF5_BAA2_62AB1ACE54EC */

