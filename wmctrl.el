;;; wmctrl.el --- Control X Window Manager from Emacs

;; Copyright (C) 2012 Takafumi Arakaki

;; Author: Takafumi Arakaki <aka.tkf at gmail.com>

;; This file is NOT part of GNU Emacs.

;; wmctrl.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; wmctrl.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with wmctrl.el.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(eval-when-compile (require 'cl))
(require 'deferred)

(defvar wmctrl-program "wmctrl")

(defvar wmctrl--window-list-re
  "^\\(0x[0-9a-f]+\\) +\\([0-9]+\\) +\\([0-9]+\\) +\\([^ ]+\\) +\\(.*\\)$")

(defun wmctrl--parse-window-list ()
  "Parse window list data in the current buffer"
  (goto-char (point-min))
  (loop while (re-search-forward wmctrl--window-list-re nil t)
        collect (list
                 :window (match-string 1)
                 :desktop (match-string 2)
                 :pid (string-to-number (match-string 3))
                 :machine (match-string 4)
                 :title (match-string 5))))

(defun wmctrl-window-list-d ()
  (deferred:$
    (deferred:process-buffer wmctrl-program "-lp")
    (deferred:nextc it
      (lambda (buffer)
        (unwind-protect
            (with-current-buffer buffer
              (wmctrl--parse-window-list))
          (kill-buffer buffer))))))

;;;###autoload
(defun wmctrl-raise-me ()
  "Set window focus on this Emacs instance."
  (deferred:$
    (wmctrl-window-list-d)
    (deferred:nextc it
      (lambda (data)
        (loop for row in data
              do (destructuring-bind
                     (&key window pid &allow-other-keys)
                     row
                   (when (= (emacs-pid) pid)
                     (return
                      (deferred:process wmctrl-program "-i" "-a" window))))
              finally (error "Emacs cannot be found by wmctrl!"))))))

(provide 'wmctrl)

;;; wmctrl.el ends here
