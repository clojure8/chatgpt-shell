;;; chatgpt-shell-zhipu.el --- Zhipu-specific logic -*- lexical-binding: t; -*-

;; Author: Qoder
;; URL: https://github.com/xenodium/chatgpt-shell

;; This package is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This package is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; Adds Zhipu (GLM) specifics for `chatgpt-shell'.
;; Implements an OpenAI-compatible chat completions flow similar to DeepSeek.

;;; Code:

(declare-function chatgpt-shell-validate-no-system-prompt "chatgpt-shell")

(cl-defun chatgpt-shell-zhipu-make-model (&key label version short-version token-width context-window validate-command other-params)
  "Create a Zhipu (GLM) model.

Set LABEL, VERSION, SHORT-VERSION, TOKEN-WIDTH, CONTEXT-WINDOW,
VALIDATE-COMMAND and OTHER-PARAMS for `chatgpt-shell-openai-make-model'."
  (chatgpt-shell-openai-make-model
   :label label
   :version version
   :short-version short-version
   :token-width token-width
   :context-window context-window
   :other-params other-params
   :validate-command #'chatgpt-shell-zhipu--validate-command
   :url-base 'chatgpt-shell-zhipu-api-url-base
   :path "/chat/completions"
   :provider "Zhipu"
   :validate-command validate-command
   :key #'chatgpt-shell-zhipu-key
   :headers #'chatgpt-shell-zhipu--make-headers
   :handler #'chatgpt-shell-zhipu--handle-command
   :filter #'chatgpt-shell-zhipu--filter-output
   :icon "openai.png"))

(defcustom chatgpt-shell-zhipu-models
  (list '(:version "glm-5.1"
          :short-version "glm-5.1"
          :label "GLM"
          :token-width 16
          :context-window 131072)
        '(:version "glm-4.5-air"
          :short-version "glm-4.5-air"
          :label "GLM"
          :token-width 16
          :context-window 131072))
  "List of Zhipu (GLM) model configurations.

Each entry is a property list with keys:
  :version - Model version string (e.g. \"glm-4.6\")
  :short-version - Short version string
  :label - Display label (e.g. \"GLM\")
  :token-width - Token width (integer)
  :context-window - Context window size in tokens (integer)

See https://open.bigmodel.cn for available models."
  :type '(repeat (plist :key-type symbol :value-type sexp))
  :group 'chatgpt-shell)

(defun chatgpt-shell-zhipu--make-model-from-plist (plist)
  "Create a Zhipu model from a property list PLIST."
  (apply #'chatgpt-shell-zhipu-make-model
         :version (plist-get plist :version)
         :short-version (plist-get plist :short-version)
         :label (plist-get plist :label)
         :token-width (plist-get plist :token-width)
         :context-window (plist-get plist :context-window)))

(defun chatgpt-shell-zhipu-models ()
  "Build a list of Zhipu LLM models from `chatgpt-shell-zhipu-models'."
  (mapcar #'chatgpt-shell-zhipu--make-model-from-plist chatgpt-shell-zhipu-models))

(defcustom chatgpt-shell-zhipu-api-url-base "https://open.bigmodel.cn/api/coding/paas/v4"
  "Zhipu API's base URL.

API url = base + path.

If you use Zhipu through a proxy service, change the URL base."
  :type 'string
  :safe #'stringp
  :group 'chatgpt-shell)

(defcustom chatgpt-shell-zhipu-key nil
  "Zhipu API key as a string or a function that loads and returns it."
  :type '(choice (function :tag "Function")
          (string :tag "String"))
  :group 'chatgpt-shell)

(defun chatgpt-shell-zhipu-key ()
  "Get the Zhipu API key."
  (cond ((stringp chatgpt-shell-zhipu-key)
         chatgpt-shell-zhipu-key)
        ((functionp chatgpt-shell-zhipu-key)
         (condition-case _err
             (funcall chatgpt-shell-zhipu-key)
           (error
            "KEY-NOT-FOUND")))
        (t
         nil)))

(cl-defun chatgpt-shell-zhipu--handle-command (&key model command context shell settings)
  "Handle ChatGPT COMMAND (prompt) using ARGS, MODEL, CONTEXT, SHELL, and SETTINGS."
  (chatgpt-shell-openai--handle-chatgpt-command
   :model model
   :command command
   :context context
   :shell shell
   :settings settings
   :key #'chatgpt-shell-zhipu-key
   :filter #'chatgpt-shell-zhipu--filter-output
   :missing-key-msg "Your chatgpt-shell-zhipu-key is missing"))

(defun chatgpt-shell-zhipu--filter-output (object)
  "Process OBJECT to extract response output."
  (chatgpt-shell-openai--filter-output object))

(defun chatgpt-shell-zhipu--make-headers (&rest args)
  "Create the API headers.

ARGS are the same as for `chatgpt-shell-openai--make-headers'."
  (apply #'chatgpt-shell-openai--make-headers
         :key #'chatgpt-shell-zhipu-key
         args))

(defun chatgpt-shell-zhipu--validate-command (_command _model _settings)
  "Return error string if command/setup isn't valid."
  (unless chatgpt-shell-zhipu-key
    "Variable `chatgpt-shell-zhipu-key' needs to be set to your key.

Try M-x set-variable chatgpt-shell-zhipu-key

or

(setq chatgpt-shell-zhipu-key \"my-key\")"))

(provide 'chatgpt-shell-zhipu)
;;; chatgpt-shell-zhipu.el ends here
