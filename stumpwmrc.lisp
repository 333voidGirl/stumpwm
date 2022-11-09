sdf:load-system :stumpwm)

(in-package :stumpwm)

(ql:quickload '(slynk find-port))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; environment vars

(defparameter *dotfiles* "$HOME/code/dotfiles/gackrc/")
(defparameter *machines*
    '(("thaumiel.lan" . desktop)
          ("katak.lan" . laptop)))
(defparameter *annex-dirs* '(("pdfs" . "/home/n1x/docs/pdfs")))

(defun is-laptop ()
    (eq (cdr (assoc (machine-instance) *machines* :test #'equalp))
	      'laptop))

(when (is-laptop)
    (load-module "battery-portable"))

#+linux
(progn
    (load-module "cpu")
      (load-module "mem")
        (load-module "net"))
(load-module "pass")
(load-module "pinentry")
(load-module "swm-ssh")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; theme

(defclass theme ()
    ((focus
           :initarg :focus :accessor focus)
        (background
	      :initarg :background :accessor background)
	   (foreground
	         :initarg :foreground :accessor foreground)
	      (border
		    :initarg :border :accessor border)
	         (font
		       :initarg :font :accessor font)))

(defclass mode-line-theme (theme)
    ((border-width
           :initarg :border-width :accessor border-width)
        (timeout
	      :initarg :timeout :accessor timeout)
	   (time-string
	         :initarg :time-string :accessor time-string)
	      (window-format
		    :initarg :window-format :accessor window-format)
	         (group-format
		       :initarg :group-format :accessor group-format)
		    (screen-mode-line-format
		          :initarg :screen-mode-line-format :accessor screen-mode-line-format)))

(defmethod initialize-instance :after ((obj theme) &key)
    (with-slots (focus foreground border font) obj
          (when (slot-boundp obj 'focus)
	          (set-focus-color focus))
	      (set-fg-color foreground)
	          (set-border-color border)
		      (when (slot-boundp obj 'font)
			      (set-font font))))

(defmethod initialize-instance :after ((obj mode-line-theme) &key)
    (with-slots (background foreground border
			                   border-width timeout time-string
					                  window-format group-format
							                 screen-mode-line-format) obj
          (when (is-laptop)
	          (setf screen-mode-line-format
			            (append screen-mode-line-format (list "^>" " %B"))))
	      (setf
		     *mode-line-background-color* background
		          *mode-line-foreground-color* foreground
			       *mode-line-border-color* border
			            *mode-line-border-width* border-width
				         *mode-line-timeout* timeout
					      *time-modeline-string* time-string
					           *window-format* window-format
						        *group-format* group-format
							     *screen-mode-line-format* screen-mode-line-format)
	          (toggle-mode-line (stumpwm:current-screen)
				                          (stumpwm:current-head))))

(defparameter *gack-theme*
    (make-instance
         'theme
	    :focus "#701543"
	       :foreground "#e60073"
	          :border "#e60073"
		     :font "IBM3270"))

(defparameter *gack-mode-line-theme
    (make-instance
         'mode-line-theme
	    :background "#000000"
	       :foreground "#e60073"
	          :border "#000000"
		     :border-width 0
		        :timeout 1
			   :time-string "%H:%M"
			      :window-format "<%n:%20t>"
			         :group-format " %t "
				    :screen-mode-line-format (list "[^B%n^b] |"
								                                     " %d |"
												                                       " %W ")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; commands

(defcommand wall-refresh () ()
	      (run-shell-command (format nil "feh --bg-fill ~aassets/wallpaper2.jpg" *dotfiles*)))

(defcommand launch-email () ()
	      (run-shell-command "st aerc"))

(defcommand launch-firefox () ()
	      (progn
		    (run-shell-command "firefox")
		        (run-shell-command "firefox -P work")))

(defcommand annex-connect () ()
	      (run-shell-command "st tmux a -t annex"))

(defcommand launch-term () ()
	      (run-shell-command "st tmux"))

(defcommand launch-plain-term () ()
	      (run-shell-command "st"))

(defcommand screenshot () ()
	      (run-shell-command "scrot -s -e 'xclip -selection clipboard -t image/png -i $f'"))

(defcommand emacs () ()
	      (run-shell-command "emacs"))

(defcommand emacsclient () ()
	      (run-shell-command "emacsclient -c"))

(defcommand emacs-serv () ()
	      (run-shell-command "emacs --fg-daemon"))

(defcommand org-capture () ()
	      (run-shell-command "emacsclient -c -F '((name . \"doom-capture\") (width . 70) (height . 25) (transient . t))' -e \"(+org-capture/open-frame \"$str\" ${key:-nil})\""))

(defcommand slynk-run (port) ((:number "Enter a port number: "))
	      (if (find-port:port-open-p port)
		      (progn
			        (slynk:create-server :dont-close t
						                                  :port port)
				        (message (format nil "Slynk running on ~a" port)))
		            (message (format nil "Slynk already running on ~a" port))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; keybinds

(set-prefix-key (kbd "s-w"))
(setf *mouse-focus-policy* :click)
(setq swm-ssh:*swm-ssh-default-term* "st")

(defmacro defkeys (name (&rest keylist))
    `(progn
            ,@(map 'list (lambda (x) `(define-key ,name (kbd ,(car x)) ,(cdr x)))
		               keylist)))

(defmacro defmap (name prefix (&rest keylist))
    `(progn
            (defvar ,name (make-sparse-keymap))
	         (defkeys ,name (,@keylist))
		      (define-key *top-map* ,(kbd prefix) ,name)))

(defmap *app-bindings* "s-a"
	    (("d" . "launch-discord")
	          ("p" . "pass-copy-menu")
		       ("f" . "launch-firefox")
		            ("e" . "launch-email")
			         ("a" . "annex-connect")
				      ("s" . "screenshot")
				           ("r" . "wall-refresh")
					        ("$" . "swm-ssh-menu")))

(defmap *emacs-bindings* "s-e"
	    (("e" . "emacsclient")
	          ("E" . "emacs")
		       ("c" . "org-capture")
		            ("s" . "emacs-serv")))

(defkeys *root-map*
	     (("," . "slynk-run")))

(defkeys *top-map*
	     (("s-a"     . *app-bindings*)
	           ("s-e"     . *emacs-bindings*)
		        ("s-g"     . *groups-map*)
			     ("s-RET"   . "launch-term")
			          ("s-S-RET" . "launch-plain-term")))

#+bsd
(progn
    (load-module "stumpwm-sndioctl")
      (defkeys *top-map*
	             (("XF86AudioLowerVolume" . "volume-up")
		             ("XF86AudioRaiseVolume" . "volume-down")
			            ("XF86AudioMute" . "toggle-mute"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; groups

(defun default-groups (grouplist)
    (grename (first grouplist))
      (map 'list (lambda (x) (gnewbg x)) (rest grouplist)))

(defvar *group-names* '("((-P)):"
			                        "(-P):"
						                        ":"
									                        "(:)"
												                        "::"
															                        "((:))"
																		                        ":(:)"
																					                        "(::)"
																								                        ":::"
																											                        "(:)(:)") )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; startup options

(setf *menu-maximum-height* 50)

(defun set-xrandr ()
    (let ((scripts (directory #P"~/code/dotfiles/gackrc/xrandr/**/*.*")))
          (loop for x in scripts
		          when (equalp (pathname-name x) (machine-instance))
			              do (run-shell-command (format nil "~a" (namestring x))))))

(defun mpd-start ()
    (run-shell-command (format nil "musicpd ~ampd/musicpd.conf" *dotfiles*))
      (run-shell-command (format nil "mpdscribble --conf ~a.config/mpd/mpdscribble.conf"
				                              (namestring (user-homedir-pathname)))))

(defun startup-hooks ()
    (default-groups *group-names*)
      (set-xrandr)
        (wall-refresh)
	  (slynk-run 4008)
	    (run-shell-command (format nil "tmux new -d -c \'~a\' -n \'~a\' -s annex"
				                                    (cdr (first *annex-dirs*))
								                                 (car (first *annex-dirs*))))
	      (loop for x in (cdr *annex-dirs*)
		            do (run-shell-command
				             (format nil "tmux new-window -n \'~a\' -c \'~a\' -t annex"
						                         (car x)
									                     (cdr x))))
	        (mpd-start))

(add-hook *start-hook* 'startup-hooks)OA
