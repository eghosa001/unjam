extends Node

const SUPPORTED_LANGUAGES := ["en", "es", "fr", "pt", "de", "it", "ha", "yo", "ig"]

const TRANSLATIONS := {
	"es": {
		"LANGUAGE":"IDIOMA","LAST LEVEL":"ÚLTIMO NIVEL",
		"HOME":"INICIO","GAMES":"JUEGOS","DAILY":"DIARIO","COLLECT":"COLECCIÓN","COLLECTION":"COLECCIÓN","SETTINGS":"AJUSTES",
		"CHOOSE GAME":"ELEGIR JUEGO","CONTINUE":"CONTINUAR","LEVEL":"NIVEL","LEVELS":"NIVELES","WORLD":"MUNDO","CURRENT":"ACTUAL",
		"NEXT":"SIGUIENTE","PREV":"ANTERIOR","BACK":"ATRÁS","PLAY":"JUGAR","PLAY NOW":"JUGAR AHORA","SOUND":"SONIDO",
		"SOUND EFFECTS":"EFECTOS DE SONIDO","MUSIC":"MÚSICA","HAPTICS":"VIBRACIÓN","COMFORT":"COMODIDAD",
		"REDUCED MOTION":"MOVIMIENTO REDUCIDO","FAST ANIMATION":"ANIMACIÓN RÁPIDA","APPEARANCE":"APARIENCIA","THEME":"TEMA",
		"SUPPORT":"AYUDA","HOW TO PLAY":"CÓMO JUGAR","PRIVACY":"PRIVACIDAD","PURCHASES":"COMPRAS","SHOP & RESTORE":"TIENDA Y RESTAURAR",
		"ON":"ACTIVADO","OFF":"DESACTIVADO","COMPLETE":"COMPLETADO","TODAY":"HOY","DONE":"HECHO","PLAYMATE SIDEKICK":"COMPAÑERO DE JUEGO",
		"BETA":"BETA","OFFLINE COACH":"GUÍA SIN CONEXIÓN","YOUR PLAYMATE":"TU COMPAÑERO","TIP":"CONSEJO","NEXT TIP":"OTRO CONSEJO",
		"PLAY THIS GAME":"JUGAR ESTE JUEGO","CHANGE GAME":"CAMBIAR JUEGO",
		"Tap blockers first when one arrow frees several paths.":"Toca primero los bloqueos cuando una flecha libere varias rutas.",
		"Trace the exit lane before moving the first arrow.":"Traza la ruta de salida antes de mover la primera flecha.",
		"Save hints for boards where two routes look equally safe.":"Guarda las pistas para tableros donde dos rutas parezcan igual de seguras.",
		"Finish one colour before opening too many new tubes.":"Completa un color antes de abrir demasiados tubos nuevos.",
		"Keep one empty tube available as a working space.":"Mantén un tubo vacío disponible como espacio de trabajo.",
		"Look for the longest same-colour stack before you pour.":"Busca la pila más larga del mismo color antes de verter.",
		"Protect the centre so every new piece has room.":"Protege el centro para que cada pieza nueva tenga espacio.",
		"Clear lines early instead of waiting for a perfect combo.":"Limpia líneas pronto en vez de esperar un combo perfecto.",
		"Before placing a piece, check all three tray pieces.":"Antes de colocar una pieza, revisa las tres piezas de la bandeja."
	},
	"fr": {
		"LANGUAGE":"LANGUE","LAST LEVEL":"DERNIER NIVEAU",
		"HOME":"ACCUEIL","GAMES":"JEUX","DAILY":"QUOTIDIEN","COLLECT":"COLLECTION","COLLECTION":"COLLECTION","SETTINGS":"RÉGLAGES",
		"CHOOSE GAME":"CHOISIR UN JEU","CONTINUE":"CONTINUER","LEVEL":"NIVEAU","LEVELS":"NIVEAUX","WORLD":"MONDE","CURRENT":"ACTUEL",
		"NEXT":"SUIVANT","PREV":"PRÉCÉDENT","BACK":"RETOUR","PLAY":"JOUER","PLAY NOW":"JOUER","SOUND":"SON",
		"SOUND EFFECTS":"EFFETS SONORES","MUSIC":"MUSIQUE","HAPTICS":"VIBRATIONS","COMFORT":"CONFORT",
		"REDUCED MOTION":"MOUVEMENTS RÉDUITS","FAST ANIMATION":"ANIMATION RAPIDE","APPEARANCE":"APPARENCE","THEME":"THÈME",
		"SUPPORT":"AIDE","HOW TO PLAY":"COMMENT JOUER","PRIVACY":"CONFIDENTIALITÉ","PURCHASES":"ACHATS","SHOP & RESTORE":"BOUTIQUE ET RESTAURATION",
		"ON":"ACTIVÉ","OFF":"DÉSACTIVÉ","COMPLETE":"TERMINÉ","TODAY":"AUJOURD’HUI","DONE":"FAIT","PLAYMATE SIDEKICK":"COMPAGNON DE JEU",
		"BETA":"BÊTA","OFFLINE COACH":"COACH HORS LIGNE","YOUR PLAYMATE":"TON COMPAGNON","TIP":"CONSEIL","NEXT TIP":"AUTRE CONSEIL",
		"PLAY THIS GAME":"JOUER À CE JEU","CHANGE GAME":"CHANGER DE JEU",
		"Tap blockers first when one arrow frees several paths.":"Touche d’abord les obstacles lorsqu’une flèche libère plusieurs chemins.",
		"Trace the exit lane before moving the first arrow.":"Repère la voie de sortie avant de déplacer la première flèche.",
		"Save hints for boards where two routes look equally safe.":"Garde les indices pour les plateaux où deux routes semblent aussi sûres.",
		"Finish one colour before opening too many new tubes.":"Termine une couleur avant d’ouvrir trop de nouveaux tubes.",
		"Keep one empty tube available as a working space.":"Garde un tube vide disponible comme espace de travail.",
		"Look for the longest same-colour stack before you pour.":"Cherche la plus longue pile de même couleur avant de verser.",
		"Protect the centre so every new piece has room.":"Protège le centre pour laisser de la place à chaque nouvelle pièce.",
		"Clear lines early instead of waiting for a perfect combo.":"Efface les lignes tôt au lieu d’attendre un combo parfait.",
		"Before placing a piece, check all three tray pieces.":"Avant de placer une pièce, vérifie les trois pièces du plateau."
	},
	"pt": {
		"LANGUAGE":"IDIOMA","LAST LEVEL":"ÚLTIMO NÍVEL",
		"HOME":"INÍCIO","GAMES":"JOGOS","DAILY":"DIÁRIO","COLLECT":"COLEÇÃO","COLLECTION":"COLEÇÃO","SETTINGS":"DEFINIÇÕES",
		"CHOOSE GAME":"ESCOLHER JOGO","CONTINUE":"CONTINUAR","LEVEL":"NÍVEL","LEVELS":"NÍVEIS","WORLD":"MUNDO","CURRENT":"ATUAL",
		"NEXT":"SEGUINTE","PREV":"ANTERIOR","BACK":"VOLTAR","PLAY":"JOGAR","PLAY NOW":"JOGAR AGORA","SOUND":"SOM",
		"SOUND EFFECTS":"EFEITOS SONOROS","MUSIC":"MÚSICA","HAPTICS":"VIBRAÇÃO","COMFORT":"CONFORTO",
		"REDUCED MOTION":"MOVIMENTO REDUZIDO","FAST ANIMATION":"ANIMAÇÃO RÁPIDA","APPEARANCE":"APARÊNCIA","THEME":"TEMA",
		"SUPPORT":"SUPORTE","HOW TO PLAY":"COMO JOGAR","PRIVACY":"PRIVACIDADE","PURCHASES":"COMPRAS","SHOP & RESTORE":"LOJA E RESTAURAR",
		"ON":"LIGADO","OFF":"DESLIGADO","COMPLETE":"CONCLUÍDO","TODAY":"HOJE","DONE":"FEITO","PLAYMATE SIDEKICK":"COMPANHEIRO DE JOGO",
		"BETA":"BETA","OFFLINE COACH":"GUIA OFFLINE","YOUR PLAYMATE":"SEU COMPANHEIRO","TIP":"DICA","NEXT TIP":"PRÓXIMA DICA",
		"PLAY THIS GAME":"JOGAR ESTE JOGO","CHANGE GAME":"MUDAR JOGO",
		"Tap blockers first when one arrow frees several paths.":"Toque primeiro nos bloqueios quando uma seta liberar vários caminhos.",
		"Trace the exit lane before moving the first arrow.":"Observe a rota de saída antes de mover a primeira seta.",
		"Save hints for boards where two routes look equally safe.":"Guarde dicas para tabuleiros onde duas rotas parecem igualmente seguras.",
		"Finish one colour before opening too many new tubes.":"Termine uma cor antes de abrir tubos novos demais.",
		"Keep one empty tube available as a working space.":"Mantenha um tubo vazio disponível como espaço de trabalho.",
		"Look for the longest same-colour stack before you pour.":"Procure a maior pilha da mesma cor antes de despejar.",
		"Protect the centre so every new piece has room.":"Proteja o centro para que cada nova peça tenha espaço.",
		"Clear lines early instead of waiting for a perfect combo.":"Limpe linhas cedo em vez de esperar um combo perfeito.",
		"Before placing a piece, check all three tray pieces.":"Antes de colocar uma peça, verifique as três peças da bandeja."
	},
	"de": {
		"LANGUAGE":"SPRACHE","LAST LEVEL":"LETZTES LEVEL",
		"HOME":"START","GAMES":"SPIELE","DAILY":"TÄGLICH","COLLECT":"SAMMLUNG","COLLECTION":"SAMMLUNG","SETTINGS":"EINSTELLUNGEN",
		"CHOOSE GAME":"SPIEL WÄHLEN","CONTINUE":"WEITER","LEVEL":"LEVEL","LEVELS":"LEVEL","WORLD":"WELT","CURRENT":"AKTUELL",
		"NEXT":"WEITER","PREV":"ZURÜCK","BACK":"ZURÜCK","PLAY":"SPIELEN","PLAY NOW":"JETZT SPIELEN","SOUND":"TON",
		"SOUND EFFECTS":"SOUNDEFFEKTE","MUSIC":"MUSIK","HAPTICS":"VIBRATION","COMFORT":"KOMFORT",
		"REDUCED MOTION":"WENIGER BEWEGUNG","FAST ANIMATION":"SCHNELLE ANIMATION","APPEARANCE":"DARSTELLUNG","THEME":"DESIGN",
		"SUPPORT":"HILFE","HOW TO PLAY":"SPIELANLEITUNG","PRIVACY":"DATENSCHUTZ","PURCHASES":"KÄUFE","SHOP & RESTORE":"SHOP & WIEDERHERSTELLEN",
		"ON":"AN","OFF":"AUS","COMPLETE":"FERTIG","TODAY":"HEUTE","DONE":"ERLEDIGT","PLAYMATE SIDEKICK":"SPIELBEGLEITER",
		"BETA":"BETA","OFFLINE COACH":"OFFLINE-COACH","YOUR PLAYMATE":"DEIN BEGLEITER","TIP":"TIPP","NEXT TIP":"NÄCHSTER TIPP",
		"PLAY THIS GAME":"DIESES SPIEL SPIELEN","CHANGE GAME":"SPIEL WECHSELN",
		"Tap blockers first when one arrow frees several paths.":"Tippe zuerst auf Blocker, wenn ein Pfeil mehrere Wege freigibt.",
		"Trace the exit lane before moving the first arrow.":"Prüfe den Ausgangsweg, bevor du den ersten Pfeil bewegst.",
		"Save hints for boards where two routes look equally safe.":"Spare Hinweise für Felder, bei denen zwei Wege gleich sicher wirken.",
		"Finish one colour before opening too many new tubes.":"Beende eine Farbe, bevor du zu viele neue Röhren öffnest.",
		"Keep one empty tube available as a working space.":"Halte eine leere Röhre als Arbeitsbereich frei.",
		"Look for the longest same-colour stack before you pour.":"Suche vor dem Gießen nach dem längsten gleichfarbigen Stapel.",
		"Protect the centre so every new piece has room.":"Halte die Mitte frei, damit neue Teile Platz haben.",
		"Clear lines early instead of waiting for a perfect combo.":"Räume Linien früh ab, statt auf die perfekte Kombo zu warten.",
		"Before placing a piece, check all three tray pieces.":"Prüfe vor dem Platzieren alle drei Teile in der Ablage."
	},
	"it": {
		"LANGUAGE":"LINGUA","LAST LEVEL":"ULTIMO LIVELLO",
		"HOME":"HOME","GAMES":"GIOCHI","DAILY":"GIORNALIERO","COLLECT":"RACCOLTA","COLLECTION":"RACCOLTA","SETTINGS":"IMPOSTAZIONI",
		"CHOOSE GAME":"SCEGLI GIOCO","CONTINUE":"CONTINUA","LEVEL":"LIVELLO","LEVELS":"LIVELLI","WORLD":"MONDO","CURRENT":"ATTUALE",
		"NEXT":"AVANTI","PREV":"INDIETRO","BACK":"INDIETRO","PLAY":"GIOCA","PLAY NOW":"GIOCA ORA","SOUND":"SUONO",
		"SOUND EFFECTS":"EFFETTI SONORI","MUSIC":"MUSICA","HAPTICS":"VIBRAZIONE","COMFORT":"COMFORT",
		"REDUCED MOTION":"MOVIMENTO RIDOTTO","FAST ANIMATION":"ANIMAZIONE RAPIDA","APPEARANCE":"ASPETTO","THEME":"TEMA",
		"SUPPORT":"SUPPORTO","HOW TO PLAY":"COME GIOCARE","PRIVACY":"PRIVACY","PURCHASES":"ACQUISTI","SHOP & RESTORE":"NEGOZIO E RIPRISTINO",
		"ON":"ON","OFF":"OFF","COMPLETE":"COMPLETO","TODAY":"OGGI","DONE":"FATTO","PLAYMATE SIDEKICK":"COMPAGNO DI GIOCO",
		"BETA":"BETA","OFFLINE COACH":"GUIDA OFFLINE","YOUR PLAYMATE":"IL TUO COMPAGNO","TIP":"SUGGERIMENTO","NEXT TIP":"ALTRO SUGGERIMENTO",
		"PLAY THIS GAME":"GIOCA A QUESTO GIOCO","CHANGE GAME":"CAMBIA GIOCO",
		"Tap blockers first when one arrow frees several paths.":"Tocca prima i blocchi quando una freccia libera più percorsi.",
		"Trace the exit lane before moving the first arrow.":"Individua l’uscita prima di muovere la prima freccia.",
		"Save hints for boards where two routes look equally safe.":"Conserva gli aiuti per le tavole in cui due percorsi sembrano ugualmente sicuri.",
		"Finish one colour before opening too many new tubes.":"Completa un colore prima di aprire troppi nuovi tubi.",
		"Keep one empty tube available as a working space.":"Tieni un tubo vuoto disponibile come spazio di lavoro.",
		"Look for the longest same-colour stack before you pour.":"Cerca la pila più lunga dello stesso colore prima di versare.",
		"Protect the centre so every new piece has room.":"Proteggi il centro così ogni nuovo pezzo ha spazio.",
		"Clear lines early instead of waiting for a perfect combo.":"Cancella le linee presto invece di aspettare una combo perfetta.",
		"Before placing a piece, check all three tray pieces.":"Prima di posizionare un pezzo, controlla tutti e tre i pezzi."
	},
	"ha": {
		"LANGUAGE":"HARSHE","LAST LEVEL":"MATAKIN ƘARSHE",
		"HOME":"GIDA","GAMES":"WASANNI","DAILY":"KULLUM","COLLECT":"TARI","COLLECTION":"TARI","SETTINGS":"SAITUNA",
		"CHOOSE GAME":"ZAƁI WASA","CONTINUE":"CI GABA","LEVEL":"MATAKI","LEVELS":"MATAKAI","WORLD":"DUNIYA","CURRENT":"YAZU",
		"NEXT":"NA GABA","PREV":"NA BAYA","BACK":"BAYA","PLAY":"YI WASA","PLAY NOW":"YI WASA YANZU","SOUND":"SAUTI",
		"MUSIC":"KIƊA","HAPTICS":"JIJJIGA","COMFORT":"SAUKI","APPEARANCE":"BAYYANA","THEME":"JIGO","SUPPORT":"TAIMAKO",
		"HOW TO PLAY":"YADDA AKE WASA","PRIVACY":"SIRRI","PURCHASES":"SAYE-SAYE","ON":"KUNNA","OFF":"KASHE","TODAY":"YAU","DONE":"AN GAMA",
		"PLAYMATE SIDEKICK":"ABOKIN WASA","BETA":"BETA","OFFLINE COACH":"MAI BA DA SHAWARA BA TARE DA INTANET BA","YOUR PLAYMATE":"ABOKIN WASANKA",
		"TIP":"SHAWARA","NEXT TIP":"SHAWARA TA GABA","PLAY THIS GAME":"YI WANNAN WASA","CHANGE GAME":"CANZA WASA"
	},
	"yo": {
		"LANGUAGE":"ÈDÈ","LAST LEVEL":"ÌPELE TÓ KẸ́YÌN",
		"HOME":"ILÉ","GAMES":"ÀWỌN ERÉ","DAILY":"OJOOJUMỌ́","COLLECT":"ÀKÓJỌ","COLLECTION":"ÀKÓJỌ","SETTINGS":"ÈTÒ",
		"CHOOSE GAME":"YAN ERÉ","CONTINUE":"TẸ̀SÍWÁJÚ","LEVEL":"ÌPELE","LEVELS":"ÀWỌN ÌPELE","WORLD":"AYÉ","CURRENT":"LỌ́WỌ́LỌ́WỌ́",
		"NEXT":"TÓ KÀN","PREV":"TẸ́LẸ̀","BACK":"PADÀ","PLAY":"ṢERÉ","PLAY NOW":"ṢERÉ BÁYÌÍ","SOUND":"OHÙN",
		"MUSIC":"ORIN","HAPTICS":"GBÌGBỌ̀N","COMFORT":"ÌTÙNÚ","APPEARANCE":"ÌRÍ","THEME":"ÀKÓRÍ","SUPPORT":"ÌRÀNLỌ́WỌ́",
		"HOW TO PLAY":"BÍ A ṢE NṢERÉ","PRIVACY":"ÀSÍRÍ","PURCHASES":"ÀWỌN RÍRÀ","ON":"TAN","OFF":"PA","TODAY":"ÒNÍ","DONE":"PARÍ",
		"PLAYMATE SIDEKICK":"ALÁBÀÁṢERÉ","BETA":"BETA","OFFLINE COACH":"OLÙRÁNṢẸ́ LÁÌSÍ ÍŃTÁNẸ́Ẹ̀TÌ","YOUR PLAYMATE":"ALÁBÀÁṢERÉ RẸ",
		"TIP":"ÌMỌ̀RÀN","NEXT TIP":"ÌMỌ̀RÀN TÓ KÀN","PLAY THIS GAME":"ṢERÉ ERÉ YÌÍ","CHANGE GAME":"YÍ ERÉ PADÀ"
	},
	"ig": {
		"LANGUAGE":"ASỤSỤ","LAST LEVEL":"ỌKWA IKPEAZỤ",
		"HOME":"ỤLỌ","GAMES":"EGWUREGWU","DAILY":"KWA ỤBỌCHỊ","COLLECT":"NCHỊKỌTA","COLLECTION":"NCHỊKỌTA","SETTINGS":"NTỌALA",
		"CHOOSE GAME":"HỌRỌ EGWUREGWU","CONTINUE":"GAA N’IHU","LEVEL":"ỌKWA","LEVELS":"ỌKWA","WORLD":"ỤWA","CURRENT":"UGBUA",
		"NEXT":"OSOTE","PREV":"GARA AGA","BACK":"LAGHACHI","PLAY":"GWUO","PLAY NOW":"GWUO UGBUA","SOUND":"ỤDA",
		"MUSIC":"EGWU","HAPTICS":"MMA JIJIIJI","COMFORT":"NKASI OBI","APPEARANCE":"ỌDỊDỊ","THEME":"ISI-OKWU","SUPPORT":"NKWADO",
		"HOW TO PLAY":"OTU ESI EGWU","PRIVACY":"NZUZO","PURCHASES":"ỊZỤ AHỊA","ON":"GBANWUO","OFF":"GBANYỤỌ","TODAY":"TAA","DONE":"EMECHAA",
		"PLAYMATE SIDEKICK":"ENYI EGWUREGWU","BETA":"BETA","OFFLINE COACH":"ONYE NDỤMỌDỤ NA-ENWEGHỊ ỊNTANET","YOUR PLAYMATE":"ENYI EGWUREGWU GỊ",
		"TIP":"NDỤMỌDỤ","NEXT TIP":"NDỤMỌDỤ ỌZỌ","PLAY THIS GAME":"GWUO EGWUREGWU A","CHANGE GAME":"GBANWEE EGWUREGWU"
	}
}

const DYNAMIC_KEYS := ["SHOP & RESTORE","HOW TO PLAY","CHOOSE GAME","PLAY THIS GAME","CHANGE GAME","NEXT TIP","SOUND EFFECTS","REDUCED MOTION","FAST ANIMATION","PLAYMATE SIDEKICK","LAST LEVEL","LANGUAGE","CONTINUE","LEVELS","LEVEL","WORLD","CURRENT","COMPLETE","DAILY","DONE","NEXT","PREV","BACK"]

var language_code := "en"

func _ready() -> void:
	language_code = _normalize_language(OS.get_locale_language())
	TranslationServer.set_locale(language_code)
	get_tree().node_added.connect(_on_node_added)
	# The save autoload is initialized after this autoload; read preferences only
	# once the initial save has loaded, and then relocalize all existing nodes.
	call_deferred("_restore_preferred_language")

func _restore_preferred_language() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.get("data") is Dictionary:
		var preference := String((save_manager.get("data") as Dictionary).get("language_code", "")).to_lower()
		if preference in SUPPORTED_LANGUAGES:
			language_code = preference
	TranslationServer.set_locale(language_code)
	_translate_existing_tree()

func set_language(code: String, persist: bool = true) -> bool:
	var requested := code.strip_edges().to_lower()
	if requested not in SUPPORTED_LANGUAGES:
		return false
	language_code = requested
	TranslationServer.set_locale(language_code)
	if persist:
		var save_manager := get_node_or_null("/root/SaveManager")
		if save_manager != null and save_manager.get("data") is Dictionary:
			var save_data: Dictionary = save_manager.get("data")
			save_data["language_code"] = requested
			save_manager.call("save")
	_translate_existing_tree()
	return true

func cycle_language() -> String:
	var index := SUPPORTED_LANGUAGES.find(language_code)
	set_language(String(SUPPORTED_LANGUAGES[(index + 1) % SUPPORTED_LANGUAGES.size()]))
	return language_code

func _normalize_language(raw: String) -> String:
	var code := raw.strip_edges().to_lower()
	if "_" in code:
		code = code.get_slice("_", 0)
	if "-" in code:
		code = code.get_slice("-", 0)
	return code if code in SUPPORTED_LANGUAGES else "en"

func localize(text_value: String) -> String:
	if language_code == "en" or text_value.is_empty():
		return text_value
	var table: Dictionary = TRANSLATIONS.get(language_code, {})
	if table.has(text_value):
		return String(table[text_value])
	var result := text_value
	for key in DYNAMIC_KEYS:
		if table.has(key):
			# Replace complete English tokens only. A plain substring replacement
			# corrupts words such as INCOMPLETE -> IN<translated COMPLETE>.
			result = _replace_whole_phrase(result, key, String(table[key]))
	return result

func _replace_whole_phrase(value: String, phrase: String, translation: String) -> String:
	if phrase.is_empty() or phrase == translation:
		return value
	var output := ""
	var cursor := 0
	while cursor < value.length():
		var found := value.find(phrase, cursor)
		if found < 0:
			output += value.substr(cursor)
			break
		var end := found + phrase.length()
		var before := value.substr(found - 1, 1) if found > 0 else ""
		var after := value.substr(end, 1) if end < value.length() else ""
		var whole := (before.is_empty() or not _is_english_word_character(before)) and (after.is_empty() or not _is_english_word_character(after))
		output += value.substr(cursor, found - cursor)
		if whole:
			output += translation
			cursor = end
		else:
			output += value.substr(found, 1)
			cursor = found + 1
	return output

func _is_english_word_character(character: String) -> bool:
	if character.is_empty():
		return false
	var c := character.unicode_at(0)
	return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95

func locale_badge() -> String:
	return language_code.to_upper()

func _on_node_added(node: Node) -> void:
	if language_code == "en":
		return
	if node is Label or node is Button or node is RichTextLabel:
		call_deferred("_translate_control", node)

func _translate_existing_tree() -> void:
	if language_code == "en":
		return
	_translate_branch(get_tree().root)

func _translate_branch(node: Node) -> void:
	_translate_control(node)
	for child in node.get_children():
		_translate_branch(child)

func _translation_source(node: Node, current: String) -> String:
	# Preserve authored English even after a control is translated. If a screen
	# changes its text dynamically, promote the new value as the next source.
	var source := String(node.get_meta("unjam_l10n_source", current))
	var last_display := String(node.get_meta("unjam_l10n_display", current))
	if current != last_display:
		source = current
	node.set_meta("unjam_l10n_source", source)
	return source

func _translate_control(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is Label:
		var label := node as Label
		var source := _translation_source(label, label.text)
		var translated := localize(source)
		label.set_meta("unjam_l10n_display", translated)
		if translated != label.text:
			label.text = translated
			_fit_localized_single_line(label, translated)
	elif node is Button:
		var button := node as Button
		var displayed := button.text
		var source := _translation_source(button, displayed)
		var translated := localize(source)
		button.set_meta("unjam_l10n_display", translated)
		# Preserve any deliberately richer accessible label, but do not leave a
		# previous language spoken when accessibility_name mirrored button text.
		if button.accessibility_name.is_empty() or button.accessibility_name == displayed or button.accessibility_name == source:
			button.accessibility_name = translated
		if translated != displayed:
			button.text = translated
			_fit_localized_single_line(button, translated)
	elif node is RichTextLabel:
		var rich := node as RichTextLabel
		var source := _translation_source(rich, rich.text)
		var translated := localize(source)
		rich.set_meta("unjam_l10n_display", translated)
		if translated != rich.text:
			rich.text = translated

func _fit_localized_single_line(control: Control, translated: String) -> void:
	# English Figma geometry is already fitted by the authoring helpers.
	# Localized buttons are often longer; resize text *inside* the existing
	# control instead of resizing hit zones over their neighbors.
	if translated.contains("\n") or control.size.x < 24.0:
		return
	if control is Label and (control as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
		return
	var font := control.get_theme_font("font")
	if font == null:
		return
	if not control.has_meta("unjam_l10n_font_size"):
		control.set_meta("unjam_l10n_font_size", control.get_theme_font_size("font_size"))
	var current_size := int(control.get_meta("unjam_l10n_font_size"))
	var min_size := maxi(9, current_size - 4)
	var available := maxf(18.0, control.size.x - (16.0 if control is Button else 4.0))
	while current_size > min_size and font.get_string_size(translated, HORIZONTAL_ALIGNMENT_LEFT, -1, current_size).x > available:
		current_size -= 1
	control.add_theme_font_size_override("font_size", current_size)
	if control is Label:
		var label := control as Label
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
