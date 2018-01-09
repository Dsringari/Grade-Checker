function validatePassword() {
	if($('main_form').USER_PASSWORD_NEW.value.length){
		if ($('main_form').USER_PASSWORD_NEW.value == $('main_form').USER_PASSWORD_CONFIRM.value) {
			return true;
		}
		alert('Your new password and confirm new password don\'t match. Please re-enter them.');
		$('main_form').USER_PASSWORD_NEW.focus();
		return false;
	}
	return true;
}