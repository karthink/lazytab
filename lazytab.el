(require 'cdlatex)
(require 'org-table)

(defun lazytab-position-cursor-and-edit ()
  ;; (if (search-backward "\?" (- (point) 100) t)
  ;;     (delete-char 1))
  (cdlatex-position-cursor)
  (lazytab-orgtbl-edit))

(defun lazytab-orgtbl-edit ()
  (when (eq major-mode 'latex-mode)
    (advice-add 'orgtbl-ctrl-c-ctrl-c :after #'lazytab-orgtbl-replace)
    (orgtbl-mode 1)
    (open-line 1)
    (insert "\n|")))

(defun lazytab-orgtbl-replace (_)
  (interactive "P")
  (unless (org-at-table-p) (user-error "Not at a table"))
  (let* ((table (org-table-to-lisp))
         (params '(:backend latex :raw t))
         (replacement-table
          (if (texmathp)
              (lazytab-orgtbl-to-amsmath table params)
            (orgtbl-to-latex table params))))
    (kill-region (org-table-begin) (org-table-end))
    (open-line 1)
    (push-mark)
    (insert replacement-table)
    (align-regexp (region-beginning) (region-end) "\\([:space:]*\\)& ")
    (orgtbl-mode -1)
    (advice-remove 'orgtbl-ctrl-c-ctrl-c #'lazytab-orgtbl-replace)))

(defun lazytab-orgtbl-to-amsmath (table params)
  (orgtbl-to-generic
   table
   (org-combine-plists
    '(:splice t
      :lstart ""
      :lend " \\\\"
      :sep " & "
      :hline nil
      :llend "")
    params)))

(defun lazytab-cdlatex-or-orgtbl-next-field ()
  (when (and (bound-and-true-p orgtbl-mode)
             (org-table-p)
             (looking-at "[[:space:]]*\\(?:|\\|$\\)")
             (let ((s (thing-at-point 'sexp)))
               (not (and s (assoc s cdlatex-command-alist-comb)))))
    (call-interactively #'org-table-next-field)
    t))

;;;###autoload
(defun lazytab-org-table-next-field-maybe ()
  (interactive)
  (if (bound-and-true-p cdlatex-mode)
      (cdlatex-tab)
    (org-table-next-field)))


;;;###autoload
(define-minor-mode lazytab-mode
  "Type in matrices, arrays and tables in LaTeX buffers with
orgtbl syntax."
  :global nil
  (if lazytab-mode
      (progn  (require 'org-table)
              (define-key orgtbl-mode-map (kbd "<tab>") 'lazytab-org-table-next-field-maybe)
              (define-key orgtbl-mode-map (kbd "TAB") 'lazytab-org-table-next-field-maybe)
              (add-hook 'cdlatex-tab-hook 'lazytab-cdlatex-or-orgtbl-next-field))
    (define-key orgtbl-mode-map (kbd "<tab>") 'org-table-next-field)
    (define-key orgtbl-mode-map (kbd "TAB") 'org-table-next-field)
    (remove-hook 'cdlatex-tab-hook 'lazytab-cdlatex-or-orgtbl-next-field)))


(provide 'lazytab)
;;; lazytab.el ends here
