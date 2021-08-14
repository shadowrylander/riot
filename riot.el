;;; riot.el --- a simple package                     -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jeet Ray

;; Author: Jeet Ray <aiern@protonmail.com>
;; Keywords: lisp
;; Version: 0.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Put a description of the package here

;;; Code:

(require 'meq)
(require 'dash)
(require 's)
(require 'ox-pandoc)

;; Adapted From:
;; Answer: https://emacs.stackexchange.com/a/3402/31428
;; User: https://emacs.stackexchange.com/users/105/drew
(add-to-list 'org-pandoc-extensions '(asciidoc . adoc))

(defvar meq/var/riot-list nil)
(defvar meq/var/riot-elist '(
    (asciidoc . adoc)
    (docbook5 . dbk)
    (dokuwiki . doku)
    (epub3 . epub)
    (gfm . md)
    (haddock . hs)
    (html5 . html)
    (latex . tex)
    (opendocument . xml)
    (plain . txt)
    (texinfo . texi)
    (zimwiki . zim)))
(defvar meq/var/riot-killed nil)

;;;###autoload
(defun meq/update-elist (econs) (add-to-list 'meq/var/riot-elist econs))

(defun meq/get-ext-name-from-file nil (interactive) (cdr (assoc buffer-file-name meq/var/riot-list)))
(defun meq/get-ext-name-from-ext (&optional ext) (interactive) (car (rassoc (or ext (meq/get-ext)) meq/var/riot-elist)))

(defun meq/after-shave nil
    (let* ((ext-name (meq/get-ext-name-from-file)))
        (when ext-name
            (funcall (meq/inconcat "org-pandoc-export-to-" (symbol-name ext-name)))
            (when meq/var/riot-killed
                (while (equal (process-status (car (last (process-list)))) 'run))
                (setq meq/var/riot-killed nil)))))
(add-hook 'after-save-hook #'meq/after-shave)

(defun meq/before-kill-buffer nil (interactive) (when (meq/get-ext-name-from-file)
    (setq meq/var/riot-killed t)
    (delete-file buffer-file-name)))
(add-hook 'kill-buffer-hook #'meq/before-kill-buffer)

(defun meq/ffns-advice (func &rest args)
    (let* ((input-buffer (apply func args))
            (input (pop args))
            (split-input (split-string input "\\."))
            (ext (car (last split-input)))
            (ext-name (meq/get-ext-name-from-ext (intern ext)))
            (output (s-chop-suffix "." (string-join (append (butlast split-input) (list "org")) "."))))
        (if (not (and (rassoc (intern ext) meq/var/riot-elist) (not (string= ext "org"))))
            input-buffer
            (call-process "pandoc" nil nil nil input "-f" (symbol-name ext-name) "-t" "org" "-so" output)
            (add-to-list 'meq/var/riot-list `(,output . ,ext-name))
            (apply func `(,output ,@args)))))

;; (add-hook 'emacs-startup-hook (lambda nil (interactive) (advice-add #'find-file-noselect :around #'meq/ffns-advice)))
(advice-add #'find-file-noselect :around #'meq/ffns-advice)

(provide 'riot)
;;; riot.el ends here
