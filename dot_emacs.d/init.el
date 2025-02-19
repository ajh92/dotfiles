;;; init.el --- Emacs startup file
;;; Commentary:

;;; Code:

(setq native-comp-async-report-warnings-errors nil)
(setq byte-compile-warnings '(cl-functions))

(defun my-minibuffer-setup-hook ()
  (setq gc-cons-threshold most-positive-fixnum))

(defun my-minibuffer-exit-hook ()
  (setq gc-cons-threshold (* 32 1024 1024)))

(add-hook 'minibuffer-setup-hook #'my-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my-minibuffer-exit-hook)

;;; Package Setup
(setq package-enable-at-startup nil)
(setq straight-recipes-emacsmirror-use-mirror t)
(setq straight-use-package-by-default t)
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(add-to-list 'load-path (concat user-emacs-directory "lisp/"))
(add-to-list 'load-path (concat user-emacs-directory "lisp/yasnippet"))
(add-to-list 'custom-theme-load-path (concat user-emacs-directory "themes/"))

(straight-use-package 'use-package)


;;; macOS
(when (eq system-type 'darwin) ;; mac specific settings
  (custom-set-faces
   ;; custom-set-faces was added by Custom.
   ;; If you edit it by hand, you could mess it up, so be careful.
   ;; Your init file should contain only one such instance.
   ;; If there is more than one, they won't work right.
   '(variable-pitch ((t (:family "San Francisco")))))
  (use-package exec-path-from-shell
    :ensure t
    :config
    (exec-path-from-shell-copy-env "TNS_ADMIN")
    (exec-path-from-shell-copy-env "PS_EDITOR_SERVICE")
    (exec-path-from-shell-initialize))
  (if (and (fboundp 'native-comp-available-p)
           (native-comp-available-p))
      (progn
        (message "Native comp is available")
        ;; Using Emacs.app/Contents/MacOS/bin since it was compiled with
        ;; ./configure --prefix="$PWD/nextstep/Emacs.app/Contents/MacOS"
        (add-to-list 'exec-path (concat invocation-directory "bin") t)
        (setenv "LIBRARY_PATH" (concat (getenv "LIBRARY_PATH")
                                       (when (getenv "LIBRARY_PATH")
                                         ":")
                                       ;; This is where Homebrew puts gcc libraries.
                                       (car (file-expand-wildcards
                                             (expand-file-name "~/homebrew/opt/gcc/lib/gcc/*")))))
        ;; Only set after LIBRARY_PATH can find gcc libraries.
        (setq comp-deferred-compilation t))
    (message "Native comp is *not* available"))
  
  (use-package mac-pseudo-daemon
    :ensure t)
  
  (setq mac-command-modifier 'meta)
  (setq insert-directory-program (executable-find "gls")) ;; use gnu ls (better dired support)
  (set-face-attribute 'default nil
		      :family "Menlo"
		      :height 140
		      :weight 'normal
		      :width 'normal)
  (set-face-attribute 'variable-pitch nil
		      :family "San Francisco")
  (server-start)
  (mac-pseudo-daemon-mode)
  )


;;; Windows NT
(when (string-equal system-type "windows-nt")
  (set-face-attribute 'default nil
		      :family "Consolas"
		      :height 130
		      :weight 'normal
		      :width 'normal)
  (require 'tramp)
  (set-default 'tramp-default-method "plink")

  ;; Caffeine uses F15
  (define-key special-event-map (kbd "<f15>") 'ignore)

  (setq python-environment-default-root-name "windows"))

;;; Linux
(if (string-equal system-type "gnu/linux")
    (progn
      (set-face-attribute 'default nil
			  :family "Ubuntu Mono"
			  :height 120
			  :weight 'normal
			  :width 'normal)
      ))


;;; Custom funcs
(defun ajh/add-list-to-list (dst src)
  "Similar to `add-to-list', but accepts a list as 2nd argument"
  (set dst
       (append (eval dst) src)))


(defun ajh/get-fullpath (@file-relative-path)
  "Return the full path of *file-relative-path, relative to caller's file location."
  (concat (file-name-directory (or load-file-name buffer-file-name)) @file-relative-path)
  )


;; re-open scratch buffer when killed
(defun prepare-scratch-for-kill ()
  (save-excursion
    (set-buffer (get-buffer-create "*scratch*"))
    (with-current-buffer "*scratch*"
      (lisp-interaction-mode))
    (add-hook 'kill-buffer-query-functions 'kill-scratch-buffer t)))

(defun kill-scratch-buffer ()
  (let (kill-buffer-query-functions)
    (kill-buffer (current-buffer)))
  ;; no way, *scratch* shall live
  (prepare-scratch-for-kill)
  ;; Since we "killed" it, don't let caller try too
  nil)

(prepare-scratch-for-kill)


(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)


(global-set-key (kbd "C-x C-b") 'ibuffer)


(add-hook 'sql-interactive-mode-hook
          (lambda ()
            (toggle-truncate-lines t)
            (horizontal-scroll-bar-mode 1)
            (font-lock-mode 0)))

(use-package chezmoi
  :ensure t
  :config (progn
	    (add-to-list 'completion-at-point-functions #'chezmoi-capf)))

(use-package yasnippet
  :ensure t
  :config (yas-global-mode 1))

(use-package highlight-indentation
  :ensure t
  :config (progn (set-face-background 'highlight-indentation-face "#e3e3d3")
                 (set-face-background 'highlight-indentation-current-column-face "#c3b3b3")))

(use-package which-key
  :ensure t
  :init (which-key-mode)
  :config (setq which-key-idle-delay 0.5))

(use-package multiple-cursors
  :ensure t)

(use-package avy
  :ensure t
  :bind* ("C-'" . avy-goto-char))

(use-package avy-zap
  :ensure t
  :bind (("M-z" . avy-zap-up-to-char-dwim)
	 ("M-Z" . avy-zap-to-char-dwim))
  :config (setq avy-zap-dwim-prefer-avy nil))

(use-package ace-window
  :ensure t
  :bind ("M-o" . ace-window)
  :config (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))

(use-package golden-ratio
  :ensure t
  :diminish golden-ratio-mode
  :init (golden-ratio-mode 1)
  :config (progn (setq golden-ratio-auto-scale t)
		 (add-to-list 'golden-ratio-extra-commands 'ace-window)))

(use-package sqlplus
  :ensure t
  :config
  (defadvice sqlplus-verify-buffer (before sqlplus-verify-buffer-and-reconnect activate)
    (unless (get-buffer-process (sqlplus-get-process-buffer-name connect-string))
      (sqlplus connect-string))))

(use-package explain-pause-mode
  :ensure t)

(use-package wgrep
  :ensure t)

(use-package magit
  :ensure t
  :bind(("C-c m" . magit-status))
  :config (progn
            (transient-replace-suffix 'magit-branch 'magit-checkout
              '("b" "dwim" magit-branch-or-checkout))
	    (setq magit-clone-set-remote.pushDefault t)))

(use-package beancount
  :ensure t)

(use-package vertico
  :ensure t
  :straight (:files (:defaults "extensions/*"))
  :config
  (setq vertico-cycle t)
  (setq vertico-resize nil)
  :init
  (vertico-mode))

(use-package savehist
  :init
  (savehist-mode))

;; A few more useful configurations...
(use-package emacs
  :custom
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)

  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))

(keymap-set vertico-map "?" #'minibuffer-completion-help)
(keymap-set vertico-map "M-RET" #'minibuffer-force-complete-and-exit)
(keymap-set vertico-map "M-TAB" #'minibuffer-complete)

(use-package corfu
  ;; Optional customizations
   :straight (corfu :files (:defaults "extensions/*")
                    :includes (corfu-info corfu-history))
   :config
   (setq corfu-popupinfo-delay 0)
  :custom
  (corfu-auto t)          ;; Enable auto completion
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches

  ;; Enable Corfu only for certain modes. See also `global-corfu-modes'.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))

  ;; Recommended: Enable Corfu globally.  This is recommended since Dabbrev can
  ;; be used globally (M-/).  See also the customization variable
  ;; `global-corfu-modes' to exclude certain modes.
  :init
  (global-corfu-mode)
  (corfu-popupinfo-mode))

(use-package consult
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)                  ;; Alternative: consult-fd
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("C-s" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
)

(use-package embark
  :ensure t

  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Show the Embark target at point via Eldoc. You may adjust the
  ;; Eldoc strategy, if you want to see the documentation from
  ;; multiple providers. Beware that using this can be a little
  ;; jarring since the message shown in the minibuffer can be more
  ;; than one line, causing the modeline to move up and down:

  ;; (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :ensure t ; only need to install it, embark loads it after consult if found
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; Use Dabbrev with Corfu!
(use-package dabbrev
  ;; Swap M-/ and C-M-/
  :bind (("M-/" . dabbrev-completion)
         ("C-M-/" . dabbrev-expand))
  :config
  (add-to-list 'dabbrev-ignored-buffer-regexps "\\` ")
  ;; Since 29.1, use `dabbrev-ignored-buffer-regexps' on older.
  (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode))

(use-package orderless
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '(
				   (file (styles partial-completion))
				   (eglot (styles . (orderless flex)))
				   )))

(use-package marginalia
  :ensure t
  :config
  (marginalia-mode 1))


(add-hook 'eshell-mode-hook (lambda ()
                              (setq-local corfu-auto nil)
                              (corfu-mode)))

(use-package esh-autosuggest
  :hook (eshell-mode . esh-autosuggest-mode)
  :ensure t)

(use-package rainbow-delimiters
  :ensure t
  :config (add-hook 'prog-mode-hook 'rainbow-delimiters-mode))

(use-package wc-mode
  :ensure t)

(use-package eat
  :straight (:type git :host codeberg :repo "akib/emacs-eat"
		   :files ("*.el" ("term" "term/*.el") "*.texi"
			   "*.ti" ("terminfo/e" "terminfo/e/*")
			   ("terminfo/65" "terminfo/65/*")
			   ("integration" "integration/*")
			   (:exclude ".dir-locals.el" "*-tests.el")))
  :ensure t
  :config (customize-set-variable ;; has :set code
	   'eat-semi-char-non-bound-keys
	   (append
            (list (vector meta-prefix-char ?o))
            eat-semi-char-non-bound-keys)))

(use-package jinx
  :hook (emacs-startup . global-jinx-mode)
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages)))

(use-package kubernetes
  :ensure t
  :commands (kubernetes-overview)
  :init
  (progn (setq kubernetes-poll-frequency 3600)
	 (setq kubernetes-redraw-frequency 3600)))

;;; Basic options
(setq inhibit-splash-screen t)

(display-time-mode 1)

(tool-bar-mode -1)

(show-paren-mode 1)

(setq split-width-threshold nil)

(setq visible-bell nil)
(setq ring-bell-function 'ignore)

(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

(put 'narrow-to-region 'disabled nil)

(add-to-list 'auto-mode-alist '("\\.nuspec\\'" . nxml-mode))

(add-hook 'mmm-mode-hook
          (lambda ()
            (set-face-background 'mmm-default-submode-face nil)))

;;; Keybindings
(global-set-key (kbd "M-/") 'hippie-expand)


;;; Clojure
(use-package cider
  :defer t
  :ensure t)

(use-package clojure-mode
  :defer t
  :ensure t)


(use-package elixir-mode
  :defer t
  :ensure t)


;;; F#
(use-package fsharp-mode
  :defer t
  :ensure t)

(use-package eglot-fsharp
  :after fsharp-mode
  :ensure t)


;;; Fish
(use-package fish-mode
  :ensure t)

(use-package fish-completion
  :ensure t)


;;; Javascript
(use-package js2-mode
  :ensure t
  :defer t
  :config (progn
	    (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
	    (add-hook 'js2-mode-hook (lambda () (tern-mode)))
	    )
  )

(use-package npm-mode
  :defer t
  :ensure t)

(setq js2-strict-missing-semi-warning nil)
(setq js2-missing-semi-one-line-override nil)
(setq js-indent-level 2)


;;; Markdown
(use-package markdown-mode
  :ensure t
  :config(progn (add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
		(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))))


;;; Ocaml
(use-package tuareg
  :defer t
  :ensure t)

(use-package merlin
  :defer t
  :ensure t
  :init (progn
	  (add-hook 'tuareg-mode-hook 'merlin-mode)
	  (add-hook 'caml-mode-hook 'merlin-mode)))

(use-package utop
  :defer t
  :ensure t)


;;; Powershell
(use-package powershell
  :ensure t)

;;; TODO -- Fix this someday
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `(powershell-mode . (,(or (executable-find "powershell") (executable-find "pwsh"))  ,(expand-file-name "run_editor_service.ps1" (getenv "PS_EDITOR_SERVICE"))))))


;;; Python
(use-package python
  :defer t
  :ensure t
  :config
  ;; Remove guess indent python message
  (setq python-indent-guess-indent-offset-verbose nil))

  ;; Format the python buffer following YAPF rules
(use-package yapfify
  :ensure t
  :defer t
  :hook (python-mode . yapf-mode))

(use-package poetry
  :ensure t
  :defer t
  :config
  ;; Checks for the correct virtualenv. Better strategy IMO because the default
  ;; one is quite slow.
  (setq poetry-tracking-strategy 'switch-buffer)
  :hook (python-mode . poetry-tracking-mode))


;;; Racket
(use-package racket-mode
  :defer t
  :ensure t)

(use-package geiser
  :defer t
  :ensure t)


;;; Ruby
(use-package inf-ruby
  :defer t
  :ensure t)

(use-package ruby-electric
  :ensure t)

(add-to-list 'auto-mode-alist
             '("\\(?:\\.rb\\|ru\\|rake\\|thor\\|jbuilder\\|gemspec\\|podspec\\|/\\(?:Gem\\|Rake\\|Cap\\|Thor\\|Vagrant\\|Guard\\|Pod\\)file\\)\\'" . ruby-mode))

(add-hook 'ruby-mode-hook 'highlight-indentation-mode)


;;; Terraform
(use-package terraform-mode
  :ensure t)


;;; YAML
(use-package yaml-mode
  :ensure t)

(add-hook 'yaml-mode-hook 'highlight-indentation-mode)

;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

(set-default 'tramp-auto-save-directory temporary-file-directory)

;; stop asking whether to save newly added abbrev when quitting emacs
(setq save-abbrevs nil)
;; turn on abbrev mode globally
(setq-default abbrev-mode t)

(setq backup-by-copying-when-linked t)
(setq delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

(setq vc-make-backup-files t)

(setq create-lockfiles nil)

(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)

(add-hook 'prog-mode-hook 'variable-pitch-mode)
(add-hook 'sqlplus-mode-hook 'variable-pitch-mode)
(add-hook 'lisp-interaction-mode-hook 'variable-pitch-mode)
(add-hook 'org-mode-hook
            '(lambda ()
               (variable-pitch-mode 1) ;; All fonts with variable pitch.
               (mapc
                (lambda (face) ;; Other fonts with fixed-pitch.
                  (set-face-attribute face nil :inherit 'fixed-pitch))
                (list 'org-table))))
(provide 'init)
