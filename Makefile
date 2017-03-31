#TODO handle this variable properly
datadir = /usr/share

THEMENAME = ravensys
THEMEDESC = RavenSys charging logo Plymouth theme.
VERSION = $(shell date '+%Y%m%d')

LOGOWIDTH = 512
LOGOHEIGHT = 160
LOGOALPHA = 70

PROGRESSLEN = 16

THROBBERLEN = 16

source-dir = src
source-files += logo.svgz
source-files += theme.plymouth
source-files += $(addprefix resource/,$(static-resources))

obj-dir = obj

progress-filename = progress
progress-animation = $(addprefix $(progress-filename)-,$(addsuffix .png,$(shell seq -w 0 $$(( $(PROGRESSLEN) - 1 )))))

throbber-filename = throbber
throbber-animation = $(addprefix $(throbber-filename)-,$(addsuffix .png,$(shell seq -w 0 $$(( $(THROBBERLEN) - 1 )))))

static-resources = background-tile.png box.png bullet.png entry.png lock.png

dist-filename = plymouth-theme-$(THEMENAME)
dist-files += $(addprefix $(source-dir)/, $(source-files))
dist-files += Makefile
dist-files += LICENSE
dist-files += README.md

release-filename = plymouth-theme-$(THEMENAME)-$(VERSION)
release-files += $(progress-animation)
release-files += $(throbber-animation)
release-files += $(static-resources)
release-files += $(THEMENAME).plymouth

install-dir = $(datadir)/plymouth/themes/$(THEMENAME)

VPATH = $(source-dir)

.PHONY: all
all: $(progress-animation) $(throbber-animation) $(static-resources) $(THEMENAME).plymouth

.PHONY: install
install:
	install -d -m 0755 $(DESTDIR)$(install-dir)
	install -m 0644 $(progress-animation) $(DESTDIR)$(install-dir) 
	install -m 0644 $(throbber-animation) $(DESTDIR)$(install-dir)
	install -m 0644 $(static-resources) $(DESTDIR)$(install-dir)
	install -m 0644 $(THEMENAME).plymouth $(DESTDIR)$(install-dir)

.PHONY: uninstall
uninstall:
	rm -f $(addprefix $(DESTDIR)$(install-dir)/,$(progress-animation))
	rm -f $(addprefix $(DESTDIR)$(install-dir)/,$(throbber-animation))
	rm -f $(addprefix $(DESTDIR)$(install-dir)/,$(static-resources))
	rm -f $(DESTDIR)$(install-dir)/$(THEMENAME).plymouth
	rm -rf $(DESTDIR)$(install-dir)

.PHONY: clean
clean:
	rm -rf $(obj-dir)
	rm -f $(progress-animation) 
	rm -f $(throbber-animation)
	rm -f $(static-resources)
	rm -f $(THEMENAME).plymouth

.PHONY: cleanall
cleanall: clean
	rm -f $(dist-filename).tar.gz $(dist-filename).tar.xz 
	rm -f $(release-filename).tar.gz $(release-filename).tar.xz

.PHONY: dist
dist: $(dist-filename).tar.gz $(dist-filename).tar.xz

.PHONY: release
release: $(release-filename).tar.gz $(release-filename).tar.xz

$(THEMENAME).plymouth: theme.plymouth
	cp "$<" "$@"

$(progress-animation): $(progress-filename)-%.png: $(obj-dir)/logo-transparent.png $(obj-dir)/logo.png
	convert "$<" \
		\( "$(obj-dir)/logo.png" -gravity south -crop "0x$$(( ((10#$* * $(LOGOHEIGHT)) / ($(PROGRESSLEN) - 1)) + 1 ))+0+0" \) \
		-gravity south -composite "$@"

$(throbber-animation): $(throbber-filename)-%.png: $(obj-dir)/logo-extent.png
	convert "$<" \
		\( "$<" -blur "0x$$( if [ $* -lt $$(( $(THROBBERLEN) / 2 )) ]; then echo $$(( 10#$* * 5 )); else echo $$(( ($(THROBBERLEN) - 10#$* - 1) * 5 )); fi )" \) \
		-composite "$@"

$(static-resources): %: resource/%
	cp "$<" "$@"

$(obj-dir)/logo.png: logo.svgz | $(obj-dir)
	inkscape -z -e "$@" -w "$(LOGOWIDTH)" -h "$(LOGOHEIGHT)" "$<"

$(obj-dir)/logo-extent.png: $(obj-dir)/logo.png
	convert "$<" -background none -gravity center -extent "$$(echo '$(LOGOWIDTH) * 1.4 / 1' | bc)x$$(echo '$(LOGOHEIGHT) * 1.4 / 1' | bc)" "$@"

$(obj-dir)/logo-transparent.png: $(obj-dir)/logo.png
	convert "$<" -alpha on -channel a -evaluate subtract "$(LOGOALPHA)%" "$@"

$(obj-dir):
	mkdir -p "$@"

$(dist-filename).tar.gz:
	tar -czf "$@" --transform "s/^\./$(dist-filename)/" $(addprefix ./,$(dist-files))

$(dist-filename).tar.xz:
	tar -cJf "$@" --transform "s/^\./$(dist-filename)/" $(addprefix ./,$(dist-files))

$(release-filename).tar.gz: all
	tar -czf "$@" --transform "s/^\./$(release-filename)/" $(addprefix ./,$(release-files))

$(release-filename).tar.xz: all
	tar -cJf "$@" --transform "s/^\./$(release-filename)/" $(addprefix ./,$(release-files))

