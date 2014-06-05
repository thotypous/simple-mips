/* main.c: The main program for bc.  */

/*  This file is part of GNU bc.
    Copyright (C) 1991-1994, 1997, 1998, 2000 Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License , or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; see the file COPYING.  If not, write to
      The Free Software Foundation, Inc.
      59 Temple Place, Suite 330
      Boston, MA 02111 USA

    You may contact the author by:
       e-mail:  philnelson@acm.org
      us-mail:  Philip A. Nelson
                Computer Science Department, 9062
                Western Washington University
                Bellingham, WA 98226-9062
       
*************************************************************************/

#include <libc.h>
#include "bcdefs.h"
#include "global.h"
#include "proto.h"


/* Variables for processing multiple files. */
static char first_file;

/* The main program for bc. */
void
bc_main ()
{
  /* Initialize many variables. */
  compile_only = FALSE;
  use_math = TRUE;
  warn_not_std = FALSE;
  std_only = FALSE;
  interactive = TRUE;
  quiet = FALSE;
  file_names = NULL;

  line_size = 16;  /* LCD width */

  /* Initialize the machine.  */
  init_storage();
  init_load();

  /* Set up interrupts to print a message. */
  if (interactive)
    signal (SIGINT, use_quit);

  /* Initialize the front end. */
  init_tree();
  init_gen ();
  is_std_in = FALSE;
  first_file = TRUE;
  if (!open_new_file ())
    exit (1);

#if defined(LIBEDIT)
  if (interactive) {
    /* Enable libedit support. */
    edit = el_init ("bc", stdin, stdout, stderr);
    hist = history_init();
    el_set (edit, EL_EDITOR, "emacs");
    el_set (edit, EL_HIST, history, hist);
    el_set (edit, EL_PROMPT, null_prompt);
    el_source (edit, NULL);
    history (hist, &histev, H_SETSIZE, INT_MAX);
  }
#endif

#if defined(READLINE)
  if (interactive) {
    /* Readline support.  Set both application name and input file. */
    rl_readline_name = "bc";
    rl_instream = stdin;
    using_history ();
  }
#endif

  /* Do the parse. */
  yyparse ();

  /* End the compile only output with a newline. */
  if (compile_only)
    printf ("\n");

  exit (0);
}


/* This is the function that opens all the files. 
   It returns TRUE if the file was opened, otherwise
   it returns FALSE. */

int
open_new_file ()
{
  /* Set the line number. */
  line_no = 1;

  /* Check to see if we are done. */
  if (is_std_in) return (FALSE);

  /* Open the other files. */
  if (use_math && first_file)
    {
      /* Load the code from a precompiled version of the math libarary. */
      extern char *libmath[];
      char **mstr;
      char tmp;
      /* These MUST be in the order of first mention of each function.
         That is why "a" comes before "c" even though "a" is defined after
         after "c".  "a" is used in "s"! */
      tmp = lookup ("e", FUNCT);
      tmp = lookup ("l", FUNCT);
      tmp = lookup ("s", FUNCT);
      tmp = lookup ("a", FUNCT);
      tmp = lookup ("c", FUNCT);
      tmp = lookup ("j", FUNCT);
      mstr = libmath;
      while (*mstr) {
           load_code (*mstr);
           mstr++;
      }
    }
  
  /* If we fall through to here, we should return stdin. */
  first_file = FALSE;
  is_std_in = TRUE;
  return TRUE;
}


/* Message to use quit.  */

void
use_quit (sig)
     int sig;
{
  printf ("\n(interrupt) use quit to exit.\n");
  signal (SIGINT, use_quit);
}
