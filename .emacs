(add-to-list 'load-path "~/emacs/.emacs-scripts/")

(tool-bar-mode 0)
(menu-bar-mode 0)               
(scroll-bar-mode 0)
(global-display-line-numbers-mode 1)
;; (ido-mode 1)
;; (ido-everywhere 1)
;; (setq ido-enable-flex-matching t)
(fido-vertical-mode t)
(global-hl-line-mode 1)
(electric-pair-mode 1)
(set-face-background 'hl-line' "#252A34")

;; Set transparency for active and inactive states (e.g., 85% opaque)
;; (set-frame-parameter (selected-frame) 'alpha '(88 100))
;; (add-to-list 'default-frame-alist '(alpha 88 100))

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq inhibit-splash-screen t)

(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

; Turn off the bell
(defun nil-bell ())
(setq ring-bell-function 'nil-bell)




(load-theme 'modus-vivendi t)
(add-to-list 'default-frame-alist `(font .  "consolas-13"))

(require 'package)
(load-file "~/emacs/.emacs-scripts/rc-require.el")

(require 'eglot)
(add-to-list 'eglot-server-programs '((c++-mode c-mode) "clangd"))
;; Enable Eglot automatically whenever you open a C or C++ file
(add-hook 'c-mode-hook 'eglot-ensure)
(add-hook 'c++-mode-hook 'eglot-ensure)
;; Optional: Tell Eglot to automatically structure and organize Imenu by category
(setq eglot-report-progress nil) ; Cleans up the echo area noise

(rc/require 'smex)
(smex-initialize)

;;; multiple cursors
(rc/require 'multiple-cursors)


(add-hook 'c-mode-hook (lambda () (electric-indent-local-mode 1)))
(add-hook 'c++-mode-hook (lambda () (electric-indent-local-mode 1)))


(setq makescript "scripts\\build.bat")
(defvar compilation-directory-locked nil)
(defvar last-compilation-directory nil)

(defun find-project-directory-recursive ()
  "Recursively search for a makefile."
  (interactive)
  (if (file-exists-p makescript) t
      (cd "../")
      (find-project-directory-recursive)))

(defun lock-compilation-directory ()
  "The compilation process should NOT hunt for a makefile"
  (interactive)
  (setq compilation-directory-locked t)
  (message "Compilation directory is locked."))

(defun unlock-compilation-directory ()
  "The compilation process SHOULD hunt for a makefile"
  (interactive)
  (setq compilation-directory-locked nil)
  (message "Compilation directory is roaming."))

(defun find-project-directory ()
  "Find the project directory."
  (interactive)
  (setq find-project-from-directory default-directory)
  (switch-to-buffer-other-window "*compilation*")
  (if compilation-directory-locked (cd last-compilation-directory)
  (cd find-project-from-directory)
  (find-project-directory-recursive)
  (setq last-compilation-directory default-directory)))

(defun make-without-asking ()
  "Make the current build."
  (interactive)
  (if (find-project-directory)
      (compile makescript))
  (other-window 1))

(defun my/eglot-manual-hover-to-echo ()
  "Manually query the active Eglot server for hover info at point 
and display the full multi-line result in the echo area."
  (interactive)
  (if-let* ((server (eglot-current-server)))
      (jsonrpc-async-request
       server
       :textDocument/hover (eglot--TextDocumentPositionParams)
       :success-fn
       (lambda (res)
         (let* ((contents (plist-get res :contents))
                (text (cond
                       ((stringp contents) contents)
                       ((vectorp contents) (mapconcat #'identity contents "\n"))
                       ((listp contents)
                        (or (plist-get contents :value)
                            (car contents)))
                       (t nil))))
           (if text
               ;; Allow the echo area to expand to fit multi-line content
               (let ((max-mini-window-height 0.4))
                 (message "%s" text))
             (message "No hover information returned by server."))))
       :error-fn
       (lambda (err)
         (message "Eglot hover error: %s" (jsonrpc-error-message err))))
    (message "No active Eglot server for this buffer.")))

(add-hook 'eglot-managed-mode-hook (lambda () (eldoc-mode -1)))

(defun append-as-kill ()
  "Performs copy-region-as-kill as an append."
  (interactive)
  (append-next-kill)
  (copy-region-as-kill (mark) (point)))

(defun my/vscode-ctrl-delete ()
  "Delete forward like VS Code: clear horizontal whitespace or the word ahead,
stopping strictly at the end of the line."
  (interactive)
  (cond
   ;; 1. If right before a newline, delete the newline (join lines like VS Code)
   ((looking-at-p "\n")
    (delete-char 1))
   ;; 2. If facing spaces/tabs, delete all contiguous horizontal whitespace on this line
   ((looking-at-p "[ \t]+")
    (let ((orig-point (point)))
      (skip-chars-forward " \t")
      (kill-region orig-point (point))))
   ;; 3. Otherwise, kill forward to word boundary, capped at the end of the line
   (t
    (let ((orig-point (point)))
      (save-excursion
        (forward-word 1)
        (when (> (line-number-at-pos) (line-number-at-pos orig-point))
          (goto-char orig-point)
          (end-of-line))
        (kill-region orig-point (point)))))))

(defun my/vscode-ctrl-backspace ()
  "Delete backward like VS Code: clear horizontal whitespace or the word behind,
stopping strictly at the beginning of the line."
  (interactive)
  (cond
   ;; 1. If at the very beginning of a line, delete the newline backwards
   ((bolp)
    (backward-delete-char 1))
   ;; 2. If preceded by spaces/tabs, delete all contiguous horizontal whitespace backward
   ((save-excursion
      (let ((p (point)))
        (skip-chars-backward " \t")
        (> p (point))))
    (let ((orig-point (point)))
      (skip-chars-backward " \t")
      (kill-region (point) orig-point)))
   ;; 3. Otherwise, kill backward to word boundary, capped at the start of the line
   (t
    (let ((orig-point (point)))
      (save-excursion
        (backward-word 1)
        (when (< (line-number-at-pos) (line-number-at-pos orig-point))
          (goto-char orig-point)
          (beginning-of-line))
        (kill-region (point) orig-point))))))

; Navigation
(defun previous-blank-line ()
  "Moves to the previous line containing nothing but whitespace."
  (interactive)
  (search-backward-regexp "^[ \t]*\n")
)

(defun next-blank-line ()
  "Moves to the next line containing nothing but whitespace."
  (interactive)
  (forward-line)
  (search-forward-regexp "^[ \t]*\n")
  (forward-line -1)
  )


(defun my/delete-to-block-end ()
  "Delete from cursor position up to (but not including) the closing delimiter of the current block."
  (interactive)
  (let ((start (point)))
    (save-excursion
      (up-list 1)
      (backward-char 1) ; step back inside before the closing delimiter
      (kill-region start (point)))))

(defun my/delete-from-block-start ()
  "Delete from right after the opening delimiter of the current block up to the current cursor position."
  (interactive)
  (let ((orig-point (point)))
    (condition-case nil
        (save-excursion
          (backward-up-list 1)
          (forward-char 1) ; Step past the opening delimiter ({, (, or [)
          (when (< (point) orig-point)
            (kill-region (point) orig-point)))
      (error (message "Not inside a block")))))

(defun my/shift-right ()
  "Shift the active region or current line right by `tab-width` and keep region active."
  (interactive)
  (if (use-region-p)
      (let ((beg (copy-marker (region-beginning)))
            (end (copy-marker (region-end) t)))
        (indent-rigidly beg end tab-width)
        (goto-char end)
        (set-mark beg)
        (activate-mark)
        (set-marker beg nil)
        (set-marker end nil)
        (setq deactivate-mark nil)) ; Prevent Emacs from clearing the selection
    (indent-rigidly (line-beginning-position) (line-end-position) tab-width)))

(defun my/shift-left ()
  "Shift the active region or current line left by `tab-width` and keep region active."
  (interactive)
  (if (use-region-p)
      (let ((beg (copy-marker (region-beginning)))
            (end (copy-marker (region-end) t)))
        (indent-rigidly beg end (- tab-width))
        (goto-char end)
        (set-mark beg)
        (activate-mark)
        (set-marker beg nil)
        (set-marker end nil)
        (setq deactivate-mark nil)) ; Prevent Emacs from clearing the selection
    (indent-rigidly (line-beginning-position) (line-end-position) (- tab-width))))

(global-set-key (kbd "M-h") 'backward-word)
(global-set-key (kbd "M-l") 'forward-word)
(global-set-key (kbd "C-'") 'kill-line)
(global-set-key (kbd "C-x p") (lambda () (interactive) (other-window -1)))

(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->")         'mc/mark-next-like-this)
(global-set-key (kbd "C-<")         'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<")     'mc/mark-all-like-this)
(global-set-key (kbd "C-\"")        'mc/skip-to-next-like-this)
(global-set-key (kbd "C-:")         'mc/skip-to-previous-like-this)

;; Replace default M-x with Smex
(global-set-key (kbd "M-x") 'smex)

;; Build command 
(define-key global-map "\em" 'make-without-asking)

;; Handle super-tabbify (TAB completes, shift-TAB actually tabs)
(setq dabbrev-case-replace t)
(setq dabbrev-case-fold-search t)
(setq dabbrev-upcase-means-case-search t)
(abbrev-mode 1)

(global-set-key (kbd "TAB") #'my/eglot-manual-hover-to-echo)
(define-key global-map [backtab] 'dabbrev-expand)
(define-key global-map [C-tab] 'completion-at-point)


(define-key global-map "\ef" 'find-file)
(define-key global-map "\eF" 'find-file-other-window);

(global-set-key (read-kbd-macro "\eb")  'ido-switch-buffer)
(global-set-key (read-kbd-macro "\eB")  'ido-switch-buffer-other-window)


(define-key global-map "\en" 'next-error)
(define-key global-map "\eN" 'previous-error)

(global-set-key (kbd "C-n") #'flymake-goto-next-error)
(global-set-key (kbd "C-N") #'flymake-goto-prev-error)

(custom-set-variables
 '(imenu-auto-rescan t)
 '(imenu-auto-rescan-maxout 500000))
(define-key global-map "\eg" 'goto-line)
(define-key global-map "\ej" 'imenu)

;; Eglot buffer-local keys
(define-key eglot-mode-map (kbd "M-A") #'eglot-code-actions)
(define-key eglot-mode-map (kbd "M-[") #'eglot-format)

;; Bind both shortcuts for GUI and terminal compatibility
(global-set-key [C-delete] #'my/vscode-ctrl-delete)
(global-set-key (kbd "C-<backspace>") #'my/vscode-ctrl-backspace)
(global-set-key [C-backspace] #'my/vscode-ctrl-backspace)

(define-key global-map [C-up] 'previous-blank-line)
(define-key global-map [C-down] 'next-blank-line)

(define-key global-map "\C-m" 'newline-and-indent)

(define-key global-map "\e/" 'c-mark-function)

;; Jump to the beginning of the block (opening delimiter)
(global-set-key (kbd "C-9") #'backward-up-list)
;; Jump to the end of the block (closing delimiter)
(global-set-key (kbd "C-0") #'up-list)

;; Bind delete-to-block-end to Alt + e (M-e)
(global-set-key (kbd "C-e") #'my/delete-to-block-end)
;; Bind delete-from-block-start to Alt + q (M-q)
(global-set-key (kbd "C-q") #'my/delete-from-block-start)

;; Keybindings
(global-set-key (kbd "C-.") #'my/shift-right)
(global-set-key (kbd "C-,") #'my/shift-left)
