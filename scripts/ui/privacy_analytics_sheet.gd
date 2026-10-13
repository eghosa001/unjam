extends CanvasLayer

# All telemetry choices are separate from advertising consent. The analytics
# toggle starts OFF, and advertising privacy still routes to Google UMP.
var _analytics_button: Button

# Localized, plain-language consent: separate from advertising preferences.
# Full legal policy remains available from the button below.
const PRIVACY_COPY := {"en":{"heading":"PRIVACY & DATA","subheading":"OPTIONAL GAME ANALYTICS","description":"Help improve puzzle balance and tutorials. With your permission, we share anonymous totals and broad level ranges only. No player ID, device ID or purchase data.","disclosure":"OFF by default. Turning it off clears pending events. Advertising consent is separate.","toggle":"ANONYMOUS ANALYTICS","ad":"AD PRIVACY OPTIONS","policy":"VIEW PRIVACY POLICY","close":"CLOSE","on":"ON","off":"OFF"},"es":{"heading":"PRIVACIDAD Y DATOS","subheading":"ANÁLISIS OPCIONAL DEL JUEGO","description":"Ayuda a mejorar el equilibrio de los puzles y los tutoriales. Con tu permiso solo compartimos recuentos anónimos y rangos amplios de niveles. No enviamos identificadores de jugador o dispositivo ni datos de compras.","disclosure":"Desactivado de forma predeterminada. Al desactivarlo, se eliminan los eventos pendientes. El consentimiento publicitario es independiente.","toggle":"ANÁLISIS ANÓNIMO","ad":"PRIVACIDAD DE ANUNCIOS","policy":"VER POLÍTICA DE PRIVACIDAD","close":"CERRAR","on":"SÍ","off":"NO"},"fr":{"heading":"CONFIDENTIALITÉ ET DONNÉES","subheading":"STATISTIQUES DE JEU FACULTATIVES","description":"Aidez-nous à améliorer l’équilibre des puzzles et les tutoriels. Avec votre accord, seuls des totaux anonymes et de larges tranches de niveaux sont transmis. Aucun identifiant de joueur ou d’appareil ni donnée d’achat.","disclosure":"Désactivé par défaut. Désactiver cette option efface les événements en attente. Le consentement publicitaire est distinct.","toggle":"STATISTIQUES ANONYMES","ad":"OPTIONS DE PUBLICITÉ","policy":"POLITIQUE DE CONFIDENTIALITÉ","close":"FERMER","on":"OUI","off":"NON"},"pt":{"heading":"PRIVACIDADE E DADOS","subheading":"ESTATÍSTICAS OPCIONAIS DO JOGO","description":"Ajude a melhorar o equilíbrio dos desafios e os tutoriais. Com sua permissão, enviamos apenas contagens anônimas e faixas amplas de níveis. Não enviamos IDs de jogadores ou dispositivos nem dados de compras.","disclosure":"Desativado por padrão. Ao desativar, os eventos pendentes são apagados. O consentimento para anúncios é separado.","toggle":"ESTATÍSTICAS ANÔNIMAS","ad":"PRIVACIDADE DOS ANÚNCIOS","policy":"POLÍTICA DE PRIVACIDADE","close":"FECHAR","on":"SIM","off":"NÃO"},"de":{"heading":"DATENSCHUTZ & DATEN","subheading":"OPTIONALE SPIELSTATISTIK","description":"Hilf uns, Schwierigkeitsgrad und Tutorials zu verbessern. Mit deiner Einwilligung senden wir nur anonyme Ereigniszahlen und grobe Levelbereiche. Keine Spieler- oder Geräte-IDs und keine Kaufdaten.","disclosure":"Standardmäßig AUS. Beim Ausschalten werden ausstehende Ereignisse gelöscht. Die Einwilligung für Werbung ist getrennt.","toggle":"ANONYME STATISTIK","ad":"WERBE-DATENSCHUTZ","policy":"DATENSCHUTZRICHTLINIE","close":"SCHLIESSEN","on":"AN","off":"AUS"},"it":{"heading":"PRIVACY E DATI","subheading":"STATISTICHE DI GIOCO FACOLTATIVE","description":"Aiutaci a migliorare la difficoltà dei puzzle e i tutorial. Con il tuo consenso inviamo solo conteggi anonimi e fasce generali di livelli. Nessun ID del giocatore o del dispositivo né dati sugli acquisti.","disclosure":"Disattivato per impostazione predefinita. Disattivando l’opzione, gli eventi in attesa vengono eliminati. Il consenso per la pubblicità è separato.","toggle":"STATISTICHE ANONIME","ad":"PRIVACY PUBBLICITARIA","policy":"INFORMATIVA SULLA PRIVACY","close":"CHIUDI","on":"SÌ","off":"NO"},"ha":{"heading":"SIRRI DA BAYANAI","subheading":"ƘIDIDDIGAR WASA TA ZAƁI","description":"Ka taimaka wajen inganta wasannin da darussa. Idan ka yarda, muna aika adadin abubuwan wasa ba tare da sunanka ba da rukunan matakai kawai. Ba ma aika shaidar ɗan wasa ko ta na'ura ko bayanan sayayya.","disclosure":"A kashe yake tun farko. Idan ka kashe shi, za a goge abubuwan da ba a aika ba. Yarda da tallace-tallace daban take.","toggle":"ƘIDIDDIGAR SIRRI","ad":"SIRRIN TALLACE-TALLACE","policy":"DUBA DOKAR SIRRI","close":"RUFE","on":"KUNNA","off":"KASHE"},"yo":{"heading":"ÀSÍRÍ ÀTI ÀWỌN ÀLÀYÉ","subheading":"ÌṢIRÒ ERÉ TÍ KÌ Í ṢE DANDAN","description":"Ran wa lọ́wọ́ láti mú eré àti ẹ̀kọ́ rẹ̀ dára sí i. Tí o bá gbà, a máa rán iye àwọn ìṣẹ̀lẹ̀ eré láìsí orúkọ àti àgbègbè ìpele nìkan. A kì í rán ID eléré, ID ẹ̀rọ tàbí ìtàn rírà.","disclosure":"Ó wà ní PÍPA láti ìbẹ̀rẹ̀. Pípa á lẹ́ẹ̀kan sí i yóò pa àwọn ìṣẹ̀lẹ̀ tí kò tíì rán. Ìyọ̀nda ìpolówó yàtọ̀.","toggle":"ÌṢIRÒ LÁÌSÍ ORÚKỌ","ad":"ÀSÍRÍ ÌPOLOWÓ","policy":"WO ÒFIN ÀSÍRÍ","close":"PA DÉ","on":"ṢÍ","off":"PÀ"},"ig":{"heading":"NZUZO NA DATA","subheading":"NDEKỌ EGWuregwu NKE NHỌRỌ","description":"Nyere anyị aka ime ka egwuregwu na nkuzi ka mma. Ọ bụrụ na ị kweta, anyị na-eziga naanị ọnụọgụ ihe omume na ogo ọkwa n'ozuzu, na-enweghị aha. Anyị anaghị eziga ID onye egwuregwu, ID ngwaọrụ ma ọ bụ ozi ịzụrụ ihe.","disclosure":"A gbanyụrụ ya na mbụ. Ịgbanyụ ya na-ehichapụ ihe omume ndị a na-ezigabeghị. Nkwenye mgbasa ozi dị iche.","toggle":"NDEKỌ ENWEGHỊ AHA","ad":"NZUZO MGBASA OZI","policy":"LELEE IWU NZUZO","close":"MECHIE","on":"GBANYE","off":"GBANYỤ"}}

func _copy(key: String) -> String:
	var locale := String(LocalizationManager.language_code)
	var fallback: Dictionary = PRIVACY_COPY["en"]
	var values: Dictionary = PRIVACY_COPY.get(locale, fallback)
	return String(values.get(key, fallback.get(key, "")))

func _ready() -> void:
	layer = 135
	var overlay := Control.new()
	overlay.name = "PrivacySettingsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.05, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var card := PanelContainer.new()
	card.name = "PrivacySettingsCard"
	card.anchor_left = 0.06
	card.anchor_right = 0.94
	card.anchor_top = 0.04
	card.anchor_bottom = 0.96
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#262d3b")
	style.border_color = Color("#789dff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	card.add_theme_stylebox_override("panel", style)
	overlay.add_child(card)

	var scroll := ScrollContainer.new()
	scroll.name = "PrivacySettingsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	var padding := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		padding.add_theme_constant_override("margin_%s" % edge, 14)
	padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(padding)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	padding.add_child(stack)

	_label(stack, _copy("heading"), 24, Color.WHITE, true)
	_label(stack, _copy("subheading"), 16, Color("#f0d580"), true)
	var description := _label(stack, _copy("description"), 14, Color("#f5f7fc"), true)
	description.custom_minimum_size.y = 90
	_analytics_button = _button(stack, "", _toggle_analytics)
	_refresh_analytics_label()
	_label(stack, _copy("disclosure"), 13, Color("#cbd3e2"), true)
	_button(stack, _copy("ad"), _open_ad_options)
	_button(stack, _copy("policy"), _open_policy)
	var close := _button(stack, _copy("close"), close_sheet)
	_analytics_button.grab_focus.call_deferred()

func _label(parent: VBoxContainer, value: String, size: int, tint: Color, wrap: bool) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.accessibility_name = value
	label.tooltip_text = value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(parent: VBoxContainer, label: String, cb: Callable) -> Button:
	var action := Button.new()
	action.text = label
	action.accessibility_name = label
	action.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	action.focus_mode = Control.FOCUS_ALL
	action.custom_minimum_size.y = 48
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action.add_theme_font_size_override("font_size", 15)
	action.add_theme_color_override("font_color", Color.WHITE)
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#405a8c")
	box.set_corner_radius_all(12)
	box.set_content_margin_all(9)
	action.add_theme_stylebox_override("normal", box)
	action.pressed.connect(cb)
	parent.add_child(action)
	# The shared UI mount path can reset Button focus when the node enters the
	# tree. Reassert keyboard/Android accessibility focus on the live control.
	action.focus_mode = Control.FOCUS_ALL
	action.set_deferred("focus_mode", Control.FOCUS_ALL)
	return action

func _refresh_analytics_label() -> void:
	var state := _copy("on") if AnalyticsManager.analytics_opted_in() else _copy("off")
	_analytics_button.text = "%s: %s" % [_copy("toggle"), state]
	_analytics_button.accessibility_name = "%s: %s" % [_copy("toggle"), state]
	_analytics_button.tooltip_text = "No analytics events are uploaded while OFF."

func _toggle_analytics() -> void:
	AnalyticsManager.set_analytics_opt_in(not AnalyticsManager.analytics_opted_in())
	_refresh_analytics_label()

func _open_ad_options() -> void:
	PrivacyManager.show_privacy_options()

func _open_policy() -> void:
	PrivacyManager.open_privacy_policy()

func close_sheet() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_sheet()
