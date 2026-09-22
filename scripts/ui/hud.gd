extends CanvasLayer

@onready var prompt_label: Label = %PromptLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var message_timer: Timer = $MessageTimer


func set_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()


func show_message(text: String) -> void:
	message_label.text = text
	message_panel.show()
	message_timer.start()


func _on_message_timer_timeout() -> void:
	message_panel.hide()

