function editField(rowId) {
	if($(rowId+'_field').style.display=='none') {
		$(rowId+'_field').show();
		$(rowId).disabled=false;
		$(rowId+'_val').hide();
	}
}
function saveForm(stuRid) {
	if (!document.loaded) { alert('Please wait for the screen to finish loading.'); return false; } 
	if ($('main_form').validate()) { 
		saveFormFields(stuRid);
	} else {
		alert('Please fix the indicated errors.');
	}
}

/*
	Help button functions
*/
function showHelpBtn(btnId) {
	$$('img.helpBtn').each(function(el){el.hide();});
	if ($(btnId)) {
		$(btnId).show();
	}
}

function showHelp(helpObj,helpId){
	//show the help section requested
	$$('div#help_div div.helpSection').each(function(el){el.hide();});
	if($(helpId)){
		$(helpId).show();
	}
	//display the help div
	$('help_div').show(); 
	Position.clone(helpObj, $('help_div'),{setHeight:false, setWidth:false, offsetTop:21});
}

function saveFormFields(stuRid) {
	// TODO: add url variables here - i.e. page start, page_end, 
	new Ajax.Updater("message", "StudentDataVerificationAction.cfm?STUDENT_RID="+stuRid, {
		method : 'post',
		parameters: Object.extend({ evalScripts: true }, $('main_form').serialize({})),
		asynchronous : true,
		loadingtext: "Saving Options ...",
		onSuccess: function() {
			/* PreRun hook */
		},
		onComplete: function() {
			/* PostRun hook */
			$('message').show();
			reloadDisplay(stuRid);
			window.setTimeout("new Effect.Fade($('message'),{duration:1.5});",5*1000);
		},
		onFailure: function(){ 
			alert('An error has occurred. Please try again.'); 
		}
	});
}

function fadeOut(obj) {
	new Effect.Fade(obj,{duration:1.5});
}

function reloadDisplay(stuRid) {
	// TODO: add url variables here - i.e. page start, page_end, registration_type_Id
	new Ajax.Updater("verification_display", "StudentDataVerificationDisplay.cfm?STUDENT_RID="+stuRid, {
		method : 'post',
		parameters: { evalScripts: true},
		asynchronous : true,
		loadingtext: "Reloading Display",
		onSuccess: function() {
			/* PreRun hook */
		},
		onComplete: function() {
			/* PostRun hook */
			$('verification_display').fire("sapphire:elementsadded");
		},
		onFailure: function(){ 
			alert('An error has occurred. Please try again.'); 
		}
	});
}


function completeDVFormPage(stuRid,formId) {
	if(!confirm('Are you finished with this form?')) {return false;}
	jQuery.ajax({
		type: "POST",
		url: "/CommunityWebPortal/Backpack/StudentDataVerificationAJAX.cfm?AJAX_SNIPIT=SubmitDVForm",
		data:{"STUDENT_RID":stuRid,"DV_FORM_ID":formId},
		dataType: "html",
		success: function(msg){
			$J('#dv_form_body').html(msg);
		},
		error: function(msg){
			alert('There was an error.');
			$J('#dv_form_debug').html(this.ERROR);
		}
	});
}

function draw_dv_forms_list(studentRid,styleFormat,accessType) {
	if(typeof styleFormat === "undefined"){var styleFormat='1';}
	if(typeof accessType === "undefined"){var accessType='P';}
	if (studentRid.length > 0  && $J('#verification_forms')) {
		jQuery.ajax({
			type: "POST",
			url: "/CommunityWebPortal/Backpack/StudentDataVerificationAJAX.cfm?AJAX_SNIPIT=DrawFormsList",
			data:{"STUDENT_RID":studentRid,"STYLE_FORMAT":styleFormat,"ACCESS_TYPE":accessType},
			dataType: "html",
			success: function(msg){
				$J('#verification_forms').html(msg);
			},
			error: function(msg){
				alert('There was an error.');
				$J('#message').html(this.ERROR);
				}
		});
	}
}

function drawDVFormEntryPage(studentRid,formId,pageId) {
	if(typeof studentRid === "undefined"){var studentRid='';}
	if(typeof formId === "undefined"){var formId='';}
	if(typeof pageId === "undefined"){var pageId='';}
	if (studentRid.length > 0  && $J('#verification_forms')) {
		jQuery.ajax({
			type: "POST",
			url: "/CommunityWebPortal/Backpack/StudentDataVerificationAJAX.cfm?AJAX_SNIPIT=DrawFormEntryPage",
			data:{"DV_FORM_ID":formId,"STUDENT_RID":studentRid,"PAGE_ID":pageId},
			dataType: "html",
			success: function(msg){
				$J('#dv_form_display').html(msg);
				// attach smartform functionality
				$('main_form').select('form.smartform').each( SapphireLib.FormLib.attachByClass );
				$J('#main_form input.date_picker,input.date_picker24').datepicker({showOn: "button", buttonImage: SapphireLib.SapphirePrefix+'/images/icons/calendar24_h.gif', buttonImageOnly: true, buttonText: "Date Picker"});
				$J('#main_form input.date_picker16').datepicker({showOn: "button", buttonImage: SapphireLib.SapphirePrefix+'/images/icons/calendar16_h.gif', buttonImageOnly: true, buttonText: "Date Picker"});
			},
			error: function(msg){
				alert('There was an error.');
				$J('#message').html(this.ERROR);
				}
		});
	}
}

function saveDVFormPage(stuRid,formId,pageId,completeFormFlg) {
	if (!document.loaded) { alert('Please wait for the screen to finish loading.'); return false; } 
	if(typeof completeFormFlg === "undefined"){var completeFormFlg='N';}
	if ($('main_form').validate()) { 
		var formData={}; $J('form#main_form').serializeArray().each(function(el) { 
			var matches = el.name.match("^(.+)\{(.+)\}$");
			if (matches) {
				if (!formData[matches[1]]) { formData[matches[1]] = {}; }
				formData[matches[1]][matches[2]] = el.value;
			} else if (el.name.endsWith("[]")) {
				var tok = el.name.substring(0,el.name.length-2);
				if (!formData[tok]) { formData[tok] = []; }
				formData[tok].push(el.value);
			} else {
				formData[el.name] = el.value||'';
			}
		});
		jQuery.ajax({
			type: "POST",
			url: "/CommunityWebPortal/Backpack/StudentDataVerificationAJAX.cfm?AJAX_SNIPIT=SaveEntryPage",
			data:{"STUDENT_RID":stuRid,"DV_FORM_ID":formId,"PAGE_ID":pageId,FIELD_DATA:$J.toJSON(formData)},
			dataType: "html",
			success: function(msg){
				//$J('#dv_form_debug').html(msg);
				if(completeFormFlg == 'Y') {
					completeDVFormPage(stuRid,formId);
				} else {
					$J('#change_page').submit();
				}
			},
			error: function(msg){
				alert('There was an error.');
				$J('#dv_form_debug').html(this.ERROR);
			}
		});
	} else {
		alert('Please fix the indicated errors.');
	}
}

function yesNoSwitch(selObj) {
	if($J(selObj).val()=='N')
		$J(selObj).parent('div').css('color','gray');
	else {
		$J(selObj).parent('div').css('color','black');
	}
}

function checkSISValue(obj, objName) {
	if(typeof $J(obj).attr('sisvalue') !='undefined') {
		if($J(obj).attr('sisvalue')==$J(obj).val()) {
			//Value is the same as in the SIS
			$J(obj).prop('name','');
		} else {
			//Value is different from the SIS
			$J(obj).prop('name',objName);
		}
	}
}