;;; dired-imagemagick.el --- Description -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021
;;
;; Author:  <https://github.com/erikbackman>
;; Maintainer:  <erikbackman@users.noreply.github.com>
;; Created: April 24, 2021
;; Modified: April 24, 2021
;; Version: 0.0.1
;; Keywords: Symbol’s value as variable is void: finder-known-keywords
;; Homepage: https://github.com/erikbackman/emacs-imagemagick
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Description
;;
;;; Code:

(require 's)
(require 'seq)
(require 'dired)
(require 'subr-x)
(require 'ivy)

(defun intersperse (sep seq)
  "SEQ SEP."
  (mapconcat 'identity seq sep))

(defun my--log (msg)
  "Log MSG to *dired-imagemagick*."
  (with-current-buffer (get-buffer-create "*dired-imagemagick*")
    (goto-char (point-max))
    (insert msg)
    (message msg)
    (insert "\n")))

(defun my--file-name (file)
  "FILE."
  (concat (file-name-base file) "." (file-name-extension file)))

(defun my--convert-sentinel (process event)
  "I handle EVENT from PROCESS :)."
  (unless (= (process-exit-status process) 0)
    (my--log (format "convert: %s" event))
    (message "Process convert exited with a non zero exit-code: %s" event)))

;; Will eventually be refactored to run any imagemagick-command
(defun my--run-convert (args)
  "ARGS."
  (make-process
   :name "convert"
   :command (cons "convert" args)
   :connection-type 'pipe
   :sentinel #'my--convert-sentinel))

(defun my--resize (img size out)
  "IMG SIZE OUT."
  (my--run-convert `(,img "-resize" ,size ,out)))

;; We will eventually wrap all of imagemagick with a transient ui
;; We could still provide templates though..
(defun my--prompt-size ()
  "FOO."
  (let ((choices '("210x297"
                   "594x842"
                   "custom")))
    (let ((choice (ivy-completing-read "Size: " choices)))
      (if (string-equal "custom" choice)
          (read-from-minibuffer "Size: ")
        choice))))

(defun my--get-args ()
  "FOO."
  (if-let* ((files (dired-get-marked-files)))
      `(:size    ,(my--prompt-size)
        :out-dir ,(concat (dired-current-directory) "resized")
        :files   ,files)

    (my--log "No image(s) marked")))

(defun my--exec-args (args)
  "Do the things using ARGS."
  (when-let ((size (plist-get args :size))
             (out-dir (plist-get args :out-dir))
             (files (plist-get args :files)))

    (unless (seq-empty-p files)
      (unless (file-exists-p out-dir)
        (dired-create-directory out-dir))

      (seq-do (lambda (file)
                (let ((out (concat out-dir "/" (my--file-name file))))
                  (my--log (format  "Processing: %s" file))
                  (my--resize file size out)
                  (my--log (format  "Out: %s" out))))
              files))))

(defun dired-resize-marked-images ()
  "Resize marked images from a dired buffer."
  (interactive)
  (my--exec-args (my--get-args)))

(provide 'dired-imagemagick)
;;; dired-imagemagick.el ends here
