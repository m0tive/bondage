#pragma once

#ifdef _WIN32
# ifdef BONDAGE_BUILD
#  define BONDAGE_EXPORT __declspec(dllexport)
# else
#  define BONDAGE_EXPORT __declspec(dllimport)
# endif
# define BONDAGE_BEGIN_WARNING_SCOPE \
  __pragma(warning(push))\
  __pragma(warning (disable : 4251)) //< needs to have dll-interface to be used by clients of class
# define BONDAGE_END_WARNING_SCOPE \
  __pragma(warning(pop))
#else
# define NMEDITORS_EXPORT
# define BONDAGE_BEGIN_WARNING_SCOPE
# define BONDAGE_END_WARNING_SCOPE
#endif
