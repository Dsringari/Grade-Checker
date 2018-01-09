

function openHelpPopup(ProductId,ScreenID) {
	jQuery.noConflict();
	var _header = "Proficio";
	var win = "";
	if (!$('sapphire_help_popup')) {
		if (Prototype.Version.match(/^1\.5/)) {
			if (!window.sapphire_help_popup) {
				window.sapphire_help_popup = new Window("sapphire_help_popup", { className: "sapphire", title: _header, width: 700, height:375, zIndex: 99999999, effectOptions: {duration: 0.4} });
			}
			win = window.sapphire_help_popup;
			} else {
					win = new Window("sapphire_help_popup", { destroyOnClose: true, className: "sapphire", title: _header, width: 700, height:375, zIndex: 99999999, effectOptions: {duration: 0.4} });
					}
					
				//win.showCenter();
				//TODO: make dynamic URL reference?
					
					win.setAjaxContent("/CommunityWebPortal/prodvid/CMSOutput.cfm", {method:"get", parameters:"tme="+Math.random()+"&ScreenID="+ScreenID+"&ProductId="+ProductId}, true);
					
		}
	}
	function HelpButtondownload(url){
		document.getElementById('loading').style.display='';
		frame = document.createElement("iframe");
		frame.style.display = 'none';
		frame.setAttribute("id", "frame");
		frame.src=url;
		jQuery('#frame').ready(function(){
			 jQuery("#loading").fadeOut(2500);
        
		 });
		document.body.appendChild(frame);
}
