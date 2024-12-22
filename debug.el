;;; debug.el --- Description -*- lexical-binding: t; -*-

(dap-register-debug-template
  "Python :: Run org-yandex-calendar from project directory"
  (list :name "Python :: Run org-yandex-calendar from project directory"
        :type "python"
        :args ""
        :cwd "/home/fvv/projects/org-yandex-calendar/"
        :module nil
        :program "test.py"
        :request "launch"))

(dap-register-debug-template
  "Python :: Docker"
  (list :name "Python :: Run docker debug"
        :type "python"
        :args ""
        :cwd ""
        :module nil
        :program ""
        :request "attach"
        :connect (list :host "localhost" :port 5678) ))

;; (dap-register-debug-template
;;   "Python :: Attach to running process"
;;   (list :type "python"
;;         :request "attach"
;;         :processId "${command:pickProcess}"
;;         :name "Python :: Attach to running process"))
