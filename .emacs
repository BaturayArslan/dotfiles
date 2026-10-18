(add-to-list 'load-path "~/emacs/.emacs-scripts/")

(require 'package)
(load-file "~/emacs/.emacs-scripts/rc-require.el")

(rc/require 'gruber-darker-theme)
(load-theme 'gruber-darker t)

(rc/require 'smex)
(smex-initialize)

;; Replace default M-x with Smex
(global-set-key (kbd "M-x") 'smex)

(setq ido-enable-flex-matching t)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq inhibit-splash-screen t)

(tool-bar-mode 0)
(menu-bar-mode 0)               
(scroll-bar-mode 0)
(global-display-line-numbers-mode 1)
(global-set-key (kbd "M-h") 'backward-word)
(global-set-key (kbd "M-l") 'forward-word)
(global-set-key (kbd "C-'") 'kill-line)
(global-set-key (kbd "C-x p") (lambda () (interactive) (other-window -1)))

(add-to-list 'default-frame-alist `(font .  "consolas-13"))
(ido-mode 1)
(ido-everywhere 1)


;;; multiple cursors
(rc/require 'multiple-cursors)

(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->")         'mc/mark-next-like-this)
(global-set-key (kbd "C-<")         'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<")     'mc/mark-all-like-this)
(global-set-key (kbd "C-\"")        'mc/skip-to-next-like-this)
(global-set-key (kbd "C-:")         'mc/skip-to-previous-like-this)

(add-hook 'c-mode-common-hook
          (lambda ()
            ;; Use spaces instead of real tab characters
            (setq indent-tabs-mode nil)
            
            ;; Set how many spaces a tab stop represents
            (setq tab-width 4)
            (setq c-basic-offset 4)

            ;; Bind TAB to advance to the next tab stop with spaces
            (local-set-key (kbd "TAB") 'tab-to-tab-stop)
            (local-set-key (kbd "<tab>") 'tab-to-tab-stop)))

(add-hook 'c-mode-common-hook
          (lambda ()
            (c-set-offset 'substatement-open 0)))
(add-hook 'c-mode-hook (lambda () (electric-indent-local-mode 1)))
(add-hook 'c++-mode-hook (lambda () (electric-indent-local-mode 1)))
(electric-pair-mode 1)



