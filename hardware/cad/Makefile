PART ?= fit_coupon
FORMAT ?= stl
PRESET ?= budget_25x45

.PHONY: validate export release-stls check-release list

validate:
	./validate.sh

export:
	./export.sh "$(PART)" "$(FORMAT)" "$(PRESET)"

release-stls: validate
	./release_stls.sh

check-release: validate
	RELEASE_CHECK=1 ./release_stls.sh

list:
	@printf '%s\n' \
	  focus_bench_jig oled_cartridge lens_tunnel lens_retainer \
	  combiner_frame combiner_clamp combiner_shim combiner_edge_liner \
	  temple_saddle \
	  quick_release mount_adapter engine_cradle engine_clamp \
	  combiner_bracket rear_pod rear_pod_lid rear_button_retainer \
	  fit_coupon cut_template_print
