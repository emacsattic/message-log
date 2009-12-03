
;;;; -*-Emacs-Lisp-*- Save Message and Error Strings in a Buffer
;;;; Written by Eric Eide, last modified on $Date: 1994/07/26 21:29:08 $.
;;;; (C) Copyright 1992, 1994, Eric Eide and the University of Utah
;;;;
;;;; TO DO
;;;; + Provide commands for reviewing messages?
;;;;
;;;; COPYRIGHT NOTICE
;;;;
;;;; This program is free software; you can redistribute it and/or modify it
;;;; under the terms of the GNU General Public License as published by the Free
;;;; Software Foundation; either version 2 of the License, or (at your option)
;;;; any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful, but
;;;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;;;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;;;; for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License along
;;;; with GNU Emacs.  If you did not, write to the Free Software Foundation,
;;;; Inc., 675 Mass Ave., Cambridge, MA 02139, USA.

;;;; AUTHOR
;;;;
;;;; This package was written by Eric Eide (eeide@cs.utah.edu).  It is similar
;;;; to another message-saving package, "log-messages.el", written by Robert
;;;; Potter.
;;;;
;;;; Addresses:
;;;;
;;;;   Eric Eide (eeide@cs.utah.edu)
;;;;   University of Utah
;;;;   3190 Merrill Engineering Building
;;;;   Salt Lake City, Utah  84112
;;;;
;;;;   Robert Potter (rpotter@grip.cis.upenn.edu)
;;;;
;;;; Robert Potter's package is Copyright 1990 by Robert Potter.  It is
;;;; available under the terms of the GNU General Public License.

;;;; LISP CODE DIRECTORY INFORMATION
;;;;
;;;; LCD Archive Entry:
;;;; message-log|Eric Eide|eeide@cs.utah.edu|
;;;; Save `message' and `error' output strings in a buffer for later review|
;;;; $Date: 1994/07/26 21:29:08 $|$Revision: 1.1 $||

;;;; SUMMARY
;;;;
;;;; This file redefines the two standard GNU Emacs functions `message' and
;;;; `error'.  The new versions of these functions save their output in a
;;;; special buffer named "*Message-Log*".  (The name of the log buffer can be
;;;; changed.)  This log can be useful when an important message is overwritten
;;;; before you get a chance to read it.
;;;;
;;;; Message and error logging can be turned on and off by toggling the
;;;; variable `message-log-messages'.  The list of regular expressions in the
;;;; variable `message-dont-log-regexps' describes messages that should never
;;;; be logged.
;;;;
;;;; NOTE that not all of the strings that appear in the echo area can be saved
;;;; in the message log.  Messages that are produced by GNU Emacs' C code can't
;;;; be logged because they don't go through the new versions of `message' and
;;;; `error'.  These messages that cannot be logged include:
;;;;
;;;;   "Garbage collecting..."
;;;;   "Auto-saving..."
;;;;   "Loading <filename>..."
;;;;   "Wrote <filename>"
;;;;   "Quit"
;;;;
;;;; It is unfortunate that we can't log the "Wrote <filename>" messages.
;;;;
;;;; Also NOTE that this package only saves the output of the functions `error'
;;;; and `message'.  Much of the text that appears at the bottom of a GNU Emacs
;;;; screen is actually presented in the minibuffer, and the contents of the
;;;; minibuffer are not saved by this package.  For more information about the
;;;; echo area and the minibuffer, refer to Section 1.2 (The Echo Area) of the
;;;; _GNU_Emacs_Manual_ by Richard Stallman.
;;;;
;;;; This "message-log" package is compatible with GNU Emacs 18, FSF GNU Emacs
;;;; 19, and Lucid GNU Emacs 19.

;;;; YOUR .EMACS FILE
;;;;
;;;; You should load this file from within your ".emacs" file:
;;;;
;;;;   (load "message-log")
;;;;
;;;; You can change the list of messages that are saved by changing the values
;;;; of the variables `message-log-messages' and `message-dont-log-regexps'.

;; (provide 'message-log) at the end of this file.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; Here are the global variables.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst message-log-buffer-name "*Message-Log*"
  "The name of the buffer that saves the output of the functions `message' and
`error'.")

(defvar message-log-messages t
  "*When non-nil, the strings displayed by the functions `message' and `error'
are saved in a special log buffer (usually named \"*Message-Log*\").  Also see
the documentation for the variable `message-dont-log-regexps'.")

(defvar message-dont-log-regexps
  ;; This list probably needs to be updated for GNU Emacs 19.
  '("\\s-*"
    "Mark set"
    "Done\\.?"
    "Undo!"
    "\\(Failing \\)?\\([Ww]rapped \\)?\\([Rr]egexp \\)?I-search\\( backward\\)?: \\(.\\|\n\\)*"
    "Matches \\(.\\|\n\\)*"				;; Paren blinking.
    "Mismatched parentheses"				;; Paren blinking.
    "Unmatched parenthesis"				;; Paren blinking.
    "File is write protected"
    "Type .+ to remove help window\\."
    "Type .+ RET to restore old contents of help window\\."
    "Type y, n, or Space: "				;; Disabled commands.
    "Looking for a misspelled word\\.\\.\\. (status: run)" ;; Ispell.
    "Generating summary\\.\\.\\.\\( done\\| [0-9]+\\)?"	;; VM.
    "[0-9]+ messages?, [0-9]+ new, [0-9]+ unread\\."	;; VM.
    "End of message [0-9]+ from .*"			;; VM.
    "NNTP: Reading\\.\\.\\."				;; GNUS.
    "NNTP: Parsing headers\\.\\.\\. [0-9]+%"		;; GNUS.
    "NNTP: [0-9]+% of headers received\\."		;; GNUS.
    "[0-9]+ of [0-9]+ deletions"			;; Tree Dired.
    "[0-9]+"						;; Tree Dired & others.
    "Compiling .*\\.el\\.\\.\\."			;; Byte compiler.
    )
  "*A list of regular expressions that describe messages that should never be
saved in the message log buffer.  A message is saved unless one of the regular
expressions in this list matches the ENTIRE message.

Also see the documentation for the variable `message-log-messages'.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; Save the original definitions of `message' and `error'.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(if (not (fboundp 'message-original))
    (fset 'message-original (symbol-function 'message)))

(if (not (fboundp 'error-original))
    (fset 'error-original (symbol-function 'error)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; Here are the new definitions of `message' and `error'.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;;
;;;

(defun message-maybe-log-message (message-string)
  "If appropriate, save the given string in the message log buffer."
  ;; This function is carefully written to catch and handle internal errors.
  ;; It must be so -- our new `error' calls this function, and we can't afford
  ;; to have `error' cause another error!
  (if message-log-messages
      (let ((old-match-data (match-data))
	    (case-fold-search nil) ;; Don't ignore case in `string-match'.
	    (regexps message-dont-log-regexps)
	    (save t))
	(condition-case error-info
	    (progn
	      (while (and regexps save)
		(if (and (eq (string-match (car regexps) message-string) 0)
			 (= (match-end 0) (length message-string)))
		    (setq save nil)
		  (setq regexps (cdr regexps))))
	      (if save
		  (save-excursion
		    (set-buffer (get-buffer-create message-log-buffer-name))
		    (let ((buffer-read-only nil))
		      (goto-char (point-max))
		      (insert message-string ?\n)))))
	  (error
	   ;; Some sort of error occurred while deciding whether or not to save
	   ;; the message.  Record this fact in the log.
	   (condition-case nil
	       (save-excursion
		 (set-buffer (get-buffer-create message-log-buffer-name))
		 (let ((buffer-read-only nil))
		   (goto-char (point-max))
		   (insert (format "*** Message log internal error: %s\n"
				   error-info))
		   ))
	     (error
	      ;; Wow, another error!  Bail out!
	      nil))))
	(store-match-data old-match-data))
    ))

;;;
;;;
;;;

(defun message (format-string &rest arguments)
  "Print a one-line message at the bottom of the screen.

The first argument is a control string.  It may contain %s or %d or %c to print
successive following arguments.

%s means print an argument as a string, %d means print as number in decimal,
and %c means print a number as a single character.  The argument used by %s
must be a string or a symbol; the argument used by %d or %c must be a number.

If the first argument is nil, clear any existing message; let the minibuffer
contents show.  (This applies ONLY to GNU Emacs version 19 or later.)

When the variable `message-log-messages' is non-nil, the message is saved in
the message log buffer (which is usually named \"*Message-Log*\").  Certain
uninteresting messages are never saved even when `message-log-messages' is
true; see the documentation for the variable `message-dont-log-regexps'."
  (if (null format-string)
      ;; A v19-ism meaning to clear the echo area.  Note that Lucid 19.10
      ;; checks for a null format string and null arguments, while FSF GNU
      ;; Emacs 19.25 only checks for a null format string.
      (message-original nil)
    ;; Otherwise...
    (let ((message-string (apply (function format) format-string arguments)))
      (message-original "%s" message-string)
      (message-maybe-log-message message-string)
      message-string)))

;;;
;;;
;;;

(defun error (format-string &rest arguments)
  "Signal an error, making an error message by passing all args to `format'.

When the variable `message-log-messages' is non-nil, the error message is saved
in the message log buffer (which is usually named \"*Message-Log*\").  Certain
uninteresting messages are never saved even when `message-log-messages' is
true; see the documentation for the variable `message-dont-log-regexps'."
  ;; This function is carefully coded to avoid signalling its own errors!
  (let ((error-string (condition-case nil
			  (apply (function format) format-string arguments)
			(error nil))))
    (if error-string
	(message-maybe-log-message error-string))
    (while t
      (signal 'error (list error-string)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; Finally, here is the `provide' statement.
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'message-log)

;; End of file.

