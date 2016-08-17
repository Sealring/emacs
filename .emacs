(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(defvar indent-sensitive-modes
  '(coffee-mode slim-mode))
(defvar progish-modes
  '(prog-mode css-mode sgml-mode))
(defvar lispy-modes
  '(emacs-lisp-mode ielm-mode eval-expression-minibuffer-setup))
(defvar ruby-modes
  '(ruby-mode slim-mode inf-ruby-mode))
(defvar writing-modes
  '(org-mode markdown-mode fountain-mode git-commit-mode))

(defmacro def (name &rest body)
  (declare (indent 1) (debug t))
  `(defun ,name (&optional _arg)
     ,(if (stringp (car body)) (car body))
     (interactive "p")
     ,@(if (stringp (car body)) (cdr `,body) body)))
(defmacro λ (&rest body)
  (declare (indent 1) (debug t))
  `(lambda ()
     (interactive)
     ,@body))

(defmacro add-λ (hook &rest body)
  (declare (indent 1) (debug t))
  `(add-hook ,hook (lambda () ,@body)))

(defmacro hook-modes (modes &rest body)
  (declare (indent 1) (debug t))
  `(dolist (mode ,modes)
     (add-λ (intern (format "%s-hook" mode)) ,@body)))

(require 'package) 
(add-to-list 'package-archives 
             '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives 
             '("marmalade" . "https://marmalade-repo.org/packages/")) 
(when (< emacs-major-version 24) 
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize) ;; You might already have this line
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))

(def upgrade-packages
  (package-refresh-contents)
  (save-window-excursion
    (package-list-packages t)
    (package-menu-mark-upgrades)
    (condition-case nil
        (package-menu-execute t)
      (error
       (package-menu-execute)))))

(use-package lua-mode
  :ensure t
  :mode "\\.lua\\'"
  :init
  ;(folding-add-to-marks-list 'lua-mode "-- {{{" "-- }}}" nil t))
)
(use-package go-mode
  :ensure t
  :mode "\\.go\\'"
  :commands (godoc gofmt gofmt-before-save)
  :init
  (progn
    ;(folding-add-to-marks-list 'go-mode "// {{{" "// }}}" nil t)
    (defun schnouki/maybe-gofmt-before-save ()
      (when (eq major-mode 'go-mode)
	(gofmt-before-save)))
    (add-hook 'before-save-hook 'schnouki/maybe-gofmt-before-save)    
    ;; From https://github.com/bradleywright/emacs.d
    ;; Update GOPATH if there's a _vendor (gom) or vendor (gb) dir
    (defun schnouki/set-local-go-path ()
      "Sets a local GOPATH if appropriate"
      (let ((current-go-path (getenv "GOPATH")))
        (catch 'found
          (dolist (vendor-dir '("_vendor" "vendor"))
            (let ((directory (locate-dominating-file (buffer-file-name) vendor-dir)))
              (when directory
                (make-local-variable 'process-environment)
                (let ((local-go-path (concat (expand-file-name directory) vendor-dir)))
                  (if (not current-go-path)
                      (setenv "GOPATH" local-go-path)
                    (unless (string-match-p local-go-path current-go-path)
                      (setenv "GOPATH" (concat local-go-path ":" current-go-path))))
                  (setq-local go-command
                              (concat "GOPATH=\"" local-go-path ":" (expand-file-name directory) ":${GOPATH}\" " go-command))
                  (throw 'found local-go-path))))))))
    (add-hook 'go-mode-hook 'schnouki/set-local-go-path))
  :config
  (progn
    ;; http://yousefourabi.com/blog/2014/05/emacs-for-go/
    (bind-key "C-c C-f" 'gofmt go-mode-map)
    (bind-key "C-c C-g" 'go-goto-imports go-mode-map)
    (bind-key "C-c C-k" 'godoc go-mode-map)
    (bind-key "C-c C-r" 'go-remove-unused-imports go-mode-map)))

(use-package company-go
  :ensure t
  :after company
  :commands company-go
  :config (add-to-list 'company-backends 'company-go))

(use-package go-eldoc
  :ensure t
  :commands go-eldoc-setup
  :init (add-hook 'go-mode-hook 'go-eldoc-setup))

(use-package server
  :config
  (unless (server-running-p)
    (server-start)))

(use-package dash
  :ensure t
  :config (dash-enable-font-lock))

(use-package s
  :ensure t
  :bind ("M-#" . transform-symbol-at-point)
  :config
  (def transform-symbol-at-point
    (let* ((choices '((?c . s-lower-camel-case)
                      (?C . s-upper-camel-case)
                      (?_ . s-snake-case)
                      (?- . s-dashed-words)
                      (?d . s-downcase)
                      (?u . s-upcase)))
           (chars (mapcar #'car choices))
           (prompt (concat "Transform symbol at point [" chars "]: "))
           (ch (read-char-choice prompt chars))
           (fn (assoc-default ch choices))
           (symbol (thing-at-point 'symbol t))
           (bounds (bounds-of-thing-at-point 'symbol)))
      (when fn
        (delete-region (car bounds) (cdr bounds))
        (insert (funcall fn symbol))))))

(use-package tool-bar
  :defer t
  :config (tool-bar-mode -1))

(use-package scroll-bar
  :defer t
  :config (scroll-bar-mode -1))

(use-package menu-bar
  :defer t
  :config (menu-bar-mode -1))

(use-package mb-depth
  :defer t
  :config (minibuffer-depth-indicate-mode))

(use-package comint
  :bind
  (:map comint-mode-map
        ("RET"       . comint-return-dwim)
        ("s-k"       . comint-clear-buffer)
        ("M-TAB"     . comint-previous-matching-input-from-input)
        ("<M-S-tab>" . comint-next-matching-input-from-input))
  :config
  (setq comint-prompt-read-only t)
  (setq-default comint-process-echoes t
                comint-scroll-show-maximum-output nil
                comint-output-filter-functions
                '(ansi-color-process-output
                  comint-truncate-buffer
                  comint-watch-for-password-prompt))
  (defun turn-on-comint-history (history-file)
    (setq comint-input-ring-file-name history-file)
    (comint-read-input-ring 'silent))
  (defun process-shellish-output ()
    (setq truncate-lines nil)
    (text-scale-decrease 1))
  (def comint-return-dwim
    (cond
     ((comint-after-pmark-p)
      (comint-send-input))
     ((ffap-guess-file-name-at-point)
      (ffap))
     (t
      (comint-next-prompt 1))))
  (defun improve-npm-process-output (output)
    (replace-regexp-in-string "\\[[0-9]+[GK]" "" output))
  (add-to-list 'comint-preoutput-filter-functions #'improve-npm-process-output)
  (add-hook 'kill-buffer-hook #'comint-write-input-ring)
  (add-hook 'comint-mode-hook #'process-shellish-output)
  (add-λ 'kill-emacs-hook
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer (comint-write-input-ring)))))

(use-package compile
  :defer t
  :config
  (setq compilation-disable-input t
        compilation-always-kill t)
  (add-hook 'compilation-mode-hook #'process-shellish-output)
  (add-hook 'compilation-finish-functions #'alert-after-finish-in-background))

(use-package warnings
  :config
  (setq warning-suppress-types '((undo discard-info))))

(use-package executable
  :defer t
  :config
  (add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p))

(use-package saveplace
  :ensure t
  :init (setq-default save-place t)
)

(use-package dired-x
  :bind ("C-f" . dired-jump-other-window)
  :after dired)

(use-package undo-tree
  :ensure t
  :diminish t
  :config (global-undo-tree-mode)
  :bind (("C-t" . undo-tree-visualize)
	 ("C-z" . undo-tree-undo)
         ("C-S-z" . undo-tree-redo)))

(use-package newcomment
  :bind ("M-/" . comment-or-uncomment-region))

(use-package simple
  :bind ("C-k" . kill-whole-line)
  :config
  (hook-modes writing-modes
    (auto-fill-mode)
    (visual-line-mode))
  (defun pop-to-mark-command-until-new-point (orig-fun &rest args)
    (let ((p (point)))
      (dotimes (_i 10)
        (when (= p (point))
          (apply orig-fun args)))))
  (defun maybe-indent-afterwards (&optional _)
    (and (not current-prefix-arg)
         (not (member major-mode indent-sensitive-modes))
         (or (-any? #'derived-mode-p progish-modes))
         (indent-region (region-beginning) (region-end) nil)))
  (defun pop-to-process-list-buffer ()
    (pop-to-buffer "*Process List*"))
  (defun kill-line-or-join-line (orig-fun &rest args)
    (if (not (eolp))
        (apply orig-fun args)
      (forward-line)
      (join-line)))
  (defun move-beginning-of-line-or-indentation (orig-fun &rest args)
    (let ((orig-point (point)))
      (back-to-indentation)
      (when (= orig-point (point))
        (apply orig-fun args))))
  (defun backward-delete-subword (orig-fun &rest args)
    (cl-letf (((symbol-function 'kill-region) #'delete-region))
      (apply orig-fun args)))
  (advice-add 'pop-to-mark-command :around #'pop-to-mark-command-until-new-point)
  (advice-add 'yank :after #'maybe-indent-afterwards)
  (advice-add 'yank-pop :after #'maybe-indent-afterwards)
  (advice-add 'list-processes :after #'pop-to-process-list-buffer)
  (advice-add 'backward-kill-word :around #'backward-delete-subword)
  (advice-add 'kill-whole-line :after #'back-to-indentation)
  (advice-add 'kill-line :around #'kill-line-or-join-line)
  (advice-add 'move-beginning-of-line :around #'move-beginning-of-line-or-indentation)
  (setq set-mark-command-repeat-pop t
        next-error-recenter t
        async-shell-command-buffer 'new-buffer)
  (bind-keys
   :map minibuffer-local-map
   ("<escape>"  . abort-recursive-edit)
   ("M-TAB"     . previous-complete-history-element)
   ("<M-S-tab>" . next-complete-history-element)))


(use-package delsel
  :init (delete-selection-mode))

(use-package autopair
  :config (autopair-mode))

(use-package smex
  :ensure t
  :config (or (boundp 'smex-cache)
              (smex-initialize))
  ;; M-x interface with colors and completion
  :bind ("M-x" . smex))

(use-package subword
  :init (global-subword-mode))

(use-package expand-region
  :ensure t
  :bind* ("C-," . er/expand-region))
(use-package yasnippet
  :ensure t
  :config
  (yas-global-mode)
  (setq-default yas/prompt-functions '(yas/ido-prompt))
  (add-to-list 'hippie-expand-try-functions-list #'yas-hippie-try-expand))

(use-package flycheck
  :ensure t
  :config
  (global-flycheck-mode)  
  )

(use-package avy
  :ensure t
  :bind
  (("M-j" . avy-goto-char-timer)
   ("C-j" . avy-goto-word-or-subword-1)
   ("M-n" . avy-goto-line))
  :config
  (avy-setup-default))

(use-package ace-link
  :ensure t
  :bind
  ("M-g e" . avy-jump-error)
  :config
  (ace-link-setup-default)
  (defun avy-jump-error-next-error-hook ()
    (let ((compilation-buffer (compilation-find-buffer t)))
      (quit-window nil (get-buffer-window compilation-buffer))
      (recenter)))
  (def avy-jump-error
    (let ((compilation-buffer (compilation-find-buffer t))
          (next-error-hook '(avy-jump-error-next-error-hook)))
      (when compilation-buffer
        (with-current-buffer compilation-buffer
          (when (derived-mode-p 'compilation-mode)
            (pop-to-buffer compilation-buffer)
            (ace-link-compilation)))))))
(use-package ace-jump-zap
  :ensure t
  :bind ("M-z" . ace-jump-zap-up-to-char))

(use-package ace-window
  :ensure t
  :bind (([remap next-multiframe-window] . ace-window))
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package smart-newline
  :ensure t
  :bind ("<C-return>" . eol-then-smart-newline)
  :init
  (defun smart-newline-no-reindent-first (orig-fun &rest args)
    (cl-letf (((symbol-function 'reindent-then-newline-and-indent) #'newline-and-indent))
      (apply orig-fun args)))
  (hook-modes progish-modes
    (when (not (member major-mode indent-sensitive-modes))
      (smart-newline-mode))
    (advice-add 'smart-newline :around #'smart-newline-no-reindent-first))
  (def eol-then-smart-newline
    (move-end-of-line nil)
    (smart-newline)))


(use-package easy-kill
  :ensure t
  :bind (([remap kill-ring-save] . easy-kill)
         ([remap mark-sexp]      . easy-mark)))

;;(yas/load-directory yas/root
;;flycheck  C-c !- prefix
;;---------------------
(defun switch-to-previous-buffer ()
  "Switch to previously open buffer.
Repeated invocations toggle between the two most recently open buffers."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))
(global-set-key (kbd "C-c b") 'switch-to-previous-buffer)
(load-theme 'smyx t)
(add-hook 'c++-mode-hook 'my:ac-c-headers-init)
(add-hook 'c-mode-hook 'my:ac-c-headers-init)
(global-set-key (kbd "C-c b") 'switch-to-previous-buffer)
(add-hook 'c++-mode-hook (lambda () (setq flycheck-gcc-language-standard "c++11")))
;;Save configuration from a last session:
(desktop-save-mode 1)

;;Cmake ide / rtags
;(require 'rtags) ;; optional, must have rtags installed
(use-package cmake-ide
  :ensure t
  :after rtags
  :init
  (cmake-ide-setup)
  :config
  (setq rtags-completion-enabled t)
  (setq rtags-autostart-diagnostics t)
  (rtags-diagnostics)
)

(use-package fish-mode
  :ensure t
  :mode "\\.fish\\'")


(use-package irony
  :ensure t
  :defer t
  :init
  (add-hook 'c++-mode-hook 'irony-mode)
  (add-hook 'c-mode-hook 'irony-mode)
  (add-hook 'objc-mode-hook 'irony-mode)
  :config
  ;; replace the `completion-at-point' and `complete-symbol' bindings in
  ;; irony-mode's buffers by irony-mode's function
  (defun my-irony-mode-hook ()
    (define-key irony-mode-map [remap completion-at-point]
      'irony-completion-at-point-async)
    (define-key irony-mode-map [remap complete-symbol]
      'irony-completion-at-point-async))
  (add-hook 'irony-mode-hook 'my-irony-mode-hook)
  (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
  )

;; == company-mode ==
(use-package gtags
  :ensure t
  )

(use-package company
  :ensure t
  :defer t
  :after dabbrev gtags 
  :init (add-hook 'after-init-hook 'global-company-mode)
  :config
  (use-package company-irony :ensure t :defer t)
  (setq company-idle-delay              nil
	company-minimum-prefix-length   2
	company-show-numbers            t
	company-tooltip-limit           20
	company-dabbrev-downcase        nil
	company-backends                '((company-irony company-gtags)))
  :bind ("C-;" . company-complete-common)
  )
(use-package company-dabbrev
  :after company
  :config
  (setq company-dabbrev-minimum-length 2))


(use-package company-dabbrev-code
  :after company
  :config
  (setq company-dabbrev-code-modes t
        company-dabbrev-code-everywhere t))

(use-package company-emoji
  :ensure t
  :after company
  :config
  (set-fontset-font t 'symbol (font-spec :family "Apple Color Emoji") nil 'prepend)
  (hook-modes writing-modes
   (setq-local company-backends (append '(company-emoji) company-backends)))
)
(use-package company-shell
  :ensure t
  :after company
  :config
  (add-to-list 'company-backends #'company-shell)
)
(use-package company-tern
  :ensure t
  :after company
  :config
  (add-to-list 'company-backends #'company-tern))

(use-package company-web
  :ensure t
  :after company
  :config
  (with-eval-after-load 'web-mode
    (add-λ 'web-mode-hook
     (setq-local company-backends (append '(company-web-html) company-backends))))
      )
      (with-eval-after-load 'html-mode
    (add-λ 'html-mode-hook
     (setq-local company-backends (append '(company-web-html) company-backends))
      ))
      (with-eval-after-load 'slim-mode
    (add-λ 'slim-mode-hook
      (setq-local company-backends (append '(company-web-slim) company-backends))
      ))
  (with-eval-after-load 'jade-mode
    (add-λ 'jade-mode-hook
      (setq-local company-backends (append '(company-web-jade) company-backends))))


(use-package smart-tab
  :ensure t
  :config (or (boundp 'smex-cache)
  (global-smart-tab-mode)
  (setq smart-tab-using-hippie-expand t
        smart-tab-completion-functions-alist '()))
 )

(use-package recentf
  :ensure t
  :config
  (recentf-mode)
  (setq recentf-exclude '(".ido.last")
        recentf-max-saved-items 1000)	     
  (setq recentf-max-menu-items 25)
  (global-set-key "\C-x\ \C-r" 'recentf-open-files)
 )

;;^^^^^^^^^^^^^^^^
(setq auto-mode-alist (append
		       '(("CMakeLists\\.txt\\'" . cmake-mode))
		       '(("\\.cmake\\'" . cmake-mode))
		       auto-mode-alist))
(autoload 'cmake-mode "/usr/share/cmake-3.0/editors/emacs/cmake-mode.el" t)

;;Multiple cursors:
(use-package multiple-cursors
  :ensure t
  :bind (
	 ("C-S-c C-S-c" . mc/edit-lines)
	 ("C-}" . mc/mark-previous-like-this)
	 ("C-{" . mc/mark-next-like-this)
	 ("C-]" . mc/mark-all-like-this-dwim)
	 )
  :config
  (add-hook 'before-save-hook #'mc/keyboard-quit)
  )

(use-package toggle-quotes
  :ensure t
  :bind ("C-'" . toggle-quotes))
(use-package scratch
  :ensure t
  :bind ("C-c s" . scratch))

(use-package flyspell
  :config
  (hook-modes writing-modes
    (flyspell-mode)))

(use-package alpha
  :ensure t
  :config
  (set-frame-parameter (selected-frame) 'alpha 80)
  (global-set-key (kbd "C-=") 'transparency-increase)
  (global-set-key (kbd "C-+") 'transparency-decrease) 
 )

(use-package ido
  :defines ido-cur-list
  :bind
  (:map ido-common-completion-map
        ("s-K"       . ido-remove-entry-from-history)
        ("M-TAB"     . previous-history-element)
        ("<M-S-tab>" . next-history-element))
  :config
  (ido-mode)
  (setq ido-cannot-complete-command 'exit-minibuffer
        ido-use-virtual-buffers t
        ido-auto-merge-delay-time 2
        ido-create-new-buffer 'always)
  (def ido-remove-entry-from-history
    (let ((ido-entry-to-remove (ido-name (car ido-matches))) 
          (history (symbol-value hist))) 
      
      (when (and ido-entry-to-remove history)
        (set hist (delq ido-entry-to-remove history))
        (setq ido-cur-list (delete ido-entry-to-remove ido-cur-list))
        (setq ido-rescan t)))))

(use-package flx-ido
  :ensure t
  :after ido
  :config
  (flx-ido-mode)
  (setq flx-ido-use-faces nil))

(use-package ido-ubiquitous
  :ensure t
  :after ido
  :config
  (ido-ubiquitous-mode))

(use-package ido-vertical-mode
  :ensure t
  :after ido
  :config
  (ido-vertical-mode)
  (setq ido-vertical-define-keys 'C-n-C-p-up-down-left-right))


(use-package yasnippet
  :ensure t;
  :init
  
  ;; Turn on snippets
  (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
  (yas-global-mode t)

  ;; Remove Yasnippet's default tab key binding
  (define-key yas-minor-mode-map (kbd "<tab>") nil)
  (define-key yas-minor-mode-map (kbd "TAB") nil)
  ;; Set Yasnippet's key binding to shift+tab
  (define-key yas-minor-mode-map (kbd "<backtab>") 'yas-expand)
  ;; Alternatively use Control-c + tab
  (define-key yas-minor-mode-map (kbd "\C-c TAB") 'yas-expand)

  (require 'auto-complete-config)
  
  (ac-config-default)
  (global-auto-complete-mode t)
  (ac-set-trigger-key "TAB")
  (ac-set-trigger-key "<tab>")
  
  :mode ("\\.yasnippet" . snippet-mode)
  )

(use-package ido-exit-target
  :ensure t
  :after ido
  :config
  (bind-key "<C-M-return>" #'ido-exit-target-other-window ido-common-completion-map)
  (set-face-attribute 'region nil :background "#004")
  (setq frame-title-format "emacs")
  :bind
         ( ("C-c C-b" . switch-to-buffer)
           ("C-c w" . toggle-split-window)
           ("C-c C-w" . delete-other-windows)
           ("M-q" . delete-side-windows))
  :config
  (def toggle-split-window
    (if (eq last-command 'toggle-split-window)
        (progn
          (jump-to-register :toggle-split-window)
          (setq this-command 'toggle-unsplit-window))
     (window-configuration-to-register :toggle-split-window)
      (switch-to-buffer-other-window nil)))
  (def delete-side-windows
  (setq display-buffer-alist
        `((,(rx bos (or "*Flycheck errors*"
                        "*Backtrace"
                        "*Warnings"
                        "*compilation"
                        "*Help"
                        "*less-css-compilation"
                        "*Packages"
                        "*rspec-compilation"
                        "*SQL"
                        "*tldr"
                        "*ag"))
           (display-buffer-reuse-window
            display-buffer-in-side-window)
           (side            . bottom)
           (reusable-frames . visible)
           (window-height   . 0.33))
          ("." nil (reusable-frames . visible))))))
(use-package wgrep-ag
  :ensure t
  :config
  (setq wgrep-auto-save-buffer t))
(use-package projectile
  :ensure t
  :bind (("C-c p" . projectile-command-map)
        ("C-c f" . projectile-find-file))
  :config
  (setq projectile-enable-caching t)
  (put 'projectile-project-run-cmd 'safe-local-variable #'stringp)
  (defmacro make-projectile-switch-project-defun (func)
    `(function
      (lambda ()
        (interactive)
        (let ((projectile-switch-project-action ,func))
          (projectile-switch-project)))))
  (defun projectile-relevant-known-git-projects ()
    (mapcar
     (lambda (dir)
       (substring dir 0 -1))
     (cl-remove-if-not
      (lambda (project)	
        (unless (file-remote-p project)
          (file-directory-p (concat project "/.git/"))))
      (projectile-relevant-known-projects))))
  (projectile-global-mode)
  (projectile-cleanup-known-projects))
(electric-pair-mode 1)
(use-package projector
  :ensure t
  :after projectile
  :bind
  (("C-x RET"        . projector-run-shell-command-project-root)
   ("C-x m"          . projector-switch-to-or-create-project-shell)
   ("C-x <C-return>" . projector-run-default-shell-command)
   :map comint-mode-map ("s-R" . projector-rerun-buffer-process))
  :config
  (setq projector-always-background-regex
        '("^powder restart\\.*"
          "^heroku restart\\.*"
          "^heroku addons:open\\.*"
          "^spring stop"
          "^gulp publish\\.*"
          "^git push\\.*"
          "^pkill\\.*")
        projector-command-modes-alist
        '(("^heroku run console" . inf-ruby-mode))))

(use-package org
  :bind (:map org-mode-map ("," . self-with-space))
  :config
  (setq org-support-shift-select t
        org-completion-use-ido t
        org-startup-indented t)
  (bind-key "'" "’" org-mode-map (not (org-in-src-block-p))))

(use-package org-autolist
  :ensure t
  :after org
  :config (add-hook 'org-mode-hook #'org-autolist-mode))


(set-default 'cursor-type 'hbar)
(column-number-mode)
(show-paren-mode)
(when window-system (global-hl-line-mode))
(winner-mode t)
(windmove-default-keybindings)

(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

(ac-config-default)

(global-set-key (kbd "C-M-z") 'switch-window)


(powerline-center-theme)
(require 'powerline)
(setq powerline-default-separator 'wave)

(global-linum-mode t)
;;C++ specific:
(use-package cc-mode
  :ensure t
  :init
  ;; c-mode-common-hook 
  (add-hook 'c-mode-common-hook
	    (lambda ()
	      (setq c-default-style "k&r") ;; 
	      (setq indent-tabs-mode nil)  ;; 
	      (setq c-basic-offset 4)      ;; indent 4
	      )))

(use-package srefactor
  :ensure t
  :config
  (define-key c-mode-map (kbd "M-RET") 'srefactor-refactor-at-point)
  (define-key c++-mode-map (kbd "M-RET") 'srefactor-refactor-at-point))

(use-package auto-complete-c-headers 
  :ensure t
  :init
  (add-hook 'c++-mode-hook (lambda () 
			     '(setq ac-sources (append ac-sources '(ac-source-c-headers)))))
  (add-hook 'c-mode-hook (lambda () 
			   '(setq ac-sources (append ac-sources '(ac-source-c-headers))))))

(use-package function-args
  :ensure t
  :config
  (fa-config-default)

  (define-key function-args-mode-map (kbd "M-o") nil)
  (define-key c-mode-map (kbd "C-M-:") 'moo-complete)
  (define-key c++-mode-map (kbd "C-M-:") 'moo-complete)
  
  (custom-set-faces
   '(fa-face-hint ((t (:background "#3f3f3f" :foreground "#ffffff"))))
   '(fa-face-hint-bold ((t (:background "#3f3f3f" :weight bold))))
   '(fa-face-semi ((t (:background "#3f3f3f" :foreground "#ffffff" :weight bold))))
   '(fa-face-type ((t (:inherit (quote font-lock-type-face) :background "#3f3f3f"))))
   '(fa-face-type-bold ((t (:inherit (quote font-lock-type-face) :background "#999999" :bold t))))))

(use-package rtags
  :ensure t
  :after company
  :init (rtags-start-process-unless-running)
  :config  
	   (setq rtags-autostart-diagnostics t)
	   (setq rtags-completions-enabled t)
	   (define-key c-mode-base-map (kbd "<C-tab>") (function company-complete))
	   (defun my-flycheck-rtags-setup ()
	     (flycheck-select-checker 'rtags)
	     (setq-local flycheck-check-syntax-automatically nil))
	   (add-hook 'c-mode-common-hook #'my-flycheck-rtags-setup)
	   (setq-local flycheck-highlighting-mode nil) ;; RTags creates more accurate overlays.
	   (push 'company-rtags company-backends)
	   )


(provide '.emacs)
