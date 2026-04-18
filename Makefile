.PHONY: install uninstall reinstall install-drop-in uninstall-drop-in

# Commands that apt-fast can replace as a drop-in.
DROP_IN_CMDS = apt apt-get aptitude
DROP_IN_DIR  = /usr/local/bin
SBIN_TARGET  = /usr/local/sbin/apt-fast

install: apt-fast completions/bash/apt-fast
	apt-get install --force-yes -y -qq aria2
	cp apt-fast /usr/local/sbin/
	cp apt-fast.conf /etc/
	mkdir -p /etc/bash_completion.d/
	mkdir -p /usr/share/zsh/functions/Completion/Debian/
	cp completions/bash/apt-fast /etc/bash_completion.d/
	cp completions/zsh/_apt-fast /usr/share/zsh/functions/Completion/Debian/
	chown root:root /etc/bash_completion.d/apt-fast
	chown root:root /usr/share/zsh/functions/Completion/Debian/_apt-fast
	mkdir -p /usr/local/share/man/man8/
	mkdir -p /usr/local/share/man/man5/
	cp man/apt-fast.8 /usr/local/share/man/man8/
	cp man/apt-fast.conf.5 /usr/local/share/man/man5/
	gzip -f9 /usr/local/share/man/man8/apt-fast.8
	gzip -f9 /usr/local/share/man/man5/apt-fast.conf.5
	chmod +x /usr/local/sbin/apt-fast
	@echo ""
	@echo "apt-fast can act as a drop-in replacement for apt, apt-get, and aptitude."
	@printf "Create symlinks in $(DROP_IN_DIR) to replace them? [y/N] "; \
	read ans; \
	case "$$ans" in \
	  [Yy]*) $(MAKE) --no-print-directory _do_install_drop_in ;; \
	  *)     echo "Skipped. Run 'make install-drop-in' at any time to set this up." ;; \
	esac

# Standalone target for users who have already run 'make install'.
install-drop-in: $(SBIN_TARGET)
	@$(MAKE) --no-print-directory _do_install_drop_in

_do_install_drop_in:
	@# Resolve the real apt-get path before creating any symlinks, so _APTMGR
	@# in apt-fast.conf points to the real binary and avoids an infinite loop.
	@REAL_APTGET=$$(which -a apt-get 2>/dev/null | grep -v '^$(DROP_IN_DIR)' | head -1); \
	REAL_APTGET=$${REAL_APTGET:-/usr/bin/apt-get}; \
	if ! grep -q '^_APTMGR=' /etc/apt-fast.conf 2>/dev/null; then \
	  sed -i "s|^#_APTMGR=.*|_APTMGR='$$REAL_APTGET'|" /etc/apt-fast.conf; \
	  echo "Set _APTMGR=$$REAL_APTGET in /etc/apt-fast.conf"; \
	else \
	  echo "_APTMGR already set in /etc/apt-fast.conf — left unchanged"; \
	fi; \
	for cmd in $(DROP_IN_CMDS); do \
	  ln -sf $(SBIN_TARGET) $(DROP_IN_DIR)/$$cmd; \
	  echo "Created $(DROP_IN_DIR)/$$cmd -> $(SBIN_TARGET)"; \
	done; \
	echo ""; \
	echo "Done. Ensure $(DROP_IN_DIR) appears before /usr/bin in PATH."

uninstall-drop-in:
	@for cmd in $(DROP_IN_CMDS); do \
	  if [ -L $(DROP_IN_DIR)/$$cmd ] && \
	     [ "$$(readlink $(DROP_IN_DIR)/$$cmd)" = "$(SBIN_TARGET)" ]; then \
	    rm -f $(DROP_IN_DIR)/$$cmd; \
	    echo "Removed $(DROP_IN_DIR)/$$cmd"; \
	  fi; \
	done

uninstall: /usr/local/sbin/apt-fast uninstall-drop-in
	rm -rf /usr/local/sbin/apt-fast /etc/apt-fast.conf \
	/usr/local/share/man/man5/apt-fast.conf.5.gz /usr/local/share/man/man8/apt-fast.8.gz \
	/usr/share/zsh/functions/Completion/Debian/_apt-fast /etc/bash_completion.d/apt-fast
	@echo "Please manually remove deb package - aria2 if you don't need it anymore."

/usr/local/sbin/apt-fast:
	@echo "Not installed" 1>&2
	@exit 1

reinstall: uninstall install
