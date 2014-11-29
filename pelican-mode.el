(require 's)

;; ========================
;; Helper functions
;; ========================


;; ========================
;; Misc functions
;; ========================

(defun pelican-timestamp-now ()
  "Generate a Pelican-compatible timestamp."
  (format-time-string "%Y-%m-%d %H:%M"))

(defun pelican-find-in-parents (file-name)
  "Find FILE-NAME in the default directory or one of its parents, or nil."
  (let* ((parent (expand-file-name default-directory)))
    (while (and (not (file-readable-p (concat parent file-name)))
                (not (string= parent (directory-file-name parent))))
      (setq parent (file-name-directory (directory-file-name parent))))
    (let ((found (concat parent file-name)))
      (if (file-readable-p found) found nil))))

(defun pelican-find-root ()
  "Return the root of the buffer's Pelican site, or nil."
  (let ((conf (pelican-find-in-parents "pelicanconf.py")))
    (if conf (file-name-directory conf))))

(defun pelican-conf-path ()
  "Return pelicanconf.py path"
  (let ((conf (pelican-find-in-parents "pelicanconf.py")))
    (if conf conf)))

(defun pelican-field (name value)
  "Helper to format a field NAME and VALUE."
  (if value (format "%s: %s\n" name value) ""))


(defun pelican-rst-header (title date status category tags slug)
  "Generate a Pelican reStructuredText header.

All parameters but TITLE may be nil to omit them. DATE may be a
string or 't to use the current date and time."
  (let ((title (format "%s\n%s\n%s\n\n"
                       (make-string (string-width title) ?#)
                       title
                       (make-string (string-width title) ?#)))
        (status (pelican-field ":status" status))
        (category (pelican-field ":category" category))
        (tags (pelican-field ":tags" tags))
        (slug (pelican-field ":slug" slug))
        (date (if date (format ":date: %s\n"
                               (if (stringp date) date
                                 (pelican-timestamp-now)))
                "")))
    (concat title date status tags category slug "\n")))

(defun pelican-conf-var (var)
  (let* ((cmd (format "cd %s && python -c '%s = str();from pelicanconf import *; print(%s)'"
                      (pelican-find-root)
                      var
                      var))
         (output (string-trim-right (shell-command-to-string cmd))))
    (if (equal "" output) nil output)))

(defun pelican-publishconf-var (var)
  (let* ((cmd (format "cd %s && python -c '%s = str();from publishconf import *; print(%s)'"
                      (pelican-find-root)
                      var
                      var))
         (output (string-trim-right (shell-command-to-string cmd))))
    (if (equal "" output) nil output)))



;; ========================
;; Make
;; ========================

(defun pelican-make (target)
  "Execute TARGET in a Makefile at the root of the site."
  (interactive "sMake Pelican target: ")
  (let ((default-directory (pelican-find-root)))
    (if default-directory
        (let ((output (get-buffer-create "*Pelican Output*")))
          (display-buffer output)
          (pop-to-buffer output)
          (compilation-mode)
          (start-process "Pelican Makefile" output "make" target))
      (message "This doesn't look like a Pelican site."))))

(defun pelican-make-html ()
  "Generate HTML via a Makefile at the root of the site."
  (interactive)
  (pelican-make "html"))

(defun pelican-make-publish ()
  "Generate HTML via a Makefile at the root of the site."
  (interactive)
  (pelican-make "html"))


;; ========================
;; Posts
;; ========================

;;;###autoload
(defun pelican-new-post-draft (title)
  "Create new rst post draft and open it in a new buffer"
  (interactive "sPost title: ")
  (let* (
         (conf-content-var (pelican-conf-var "PATH"))
         (content-path (if conf-content-var conf-content-var "output"))
         (slug (s-dashed-words title))
         (draft-path (format "content/%s.rst" slug))
         (category "<CATEGORY>")
         (tags "<TAGS>")
         (header (pelican-rst-header
                  title
                  (pelican-timestamp-now)
                  "draft"
                  category
                  tags
                  slug)))
    (write-region header nil draft-path)
    (message "Created new rst draft at: %s" draft-path)
    (find-file draft-path)
    ))


;; ========================
;; Define mode
;; ========================

;;;###autoload
(define-minor-mode pelican-mode
  "Toggle mode"
  :lighter " Pelican")

(provide 'pelican-mode)
