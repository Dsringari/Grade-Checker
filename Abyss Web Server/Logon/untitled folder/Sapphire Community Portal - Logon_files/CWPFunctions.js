$J(function(){
    if (!$J("link[href^='/Sapphire/styles/jui_themes']").length)
        $J('head').append('<link rel="stylesheet" href="/Sapphire/styles/jui_themes/CWP_Theme_Students/jquery-ui-1.10.3.custom.css" type="text/css" />');
})
var openHelpPopup = function(ProductId, ScreenID) {
	$J.ajaxSetup ({
	   // Disable caching of AJAX responses
	   cache: false
	});
    if ($J('#helpPopupDiv').length == 0) {
        $J('body').append('<div id="helpPopupDiv" ></div>');
    }
    if (!$J("link[href^='/Sapphire/styles/jui_themes']").length)
    	$J('head').append('<link rel="stylesheet" href="/Sapphire/styles/jui_themes/CWP_Theme_Students/jquery-ui-1.10.3.custom.css" type="text/css" />');
    if (!$J("link[href='/Sapphire/styles/bootstrapScoped.min.css']").length)
    	$J('head').append('<link rel="stylesheet" href="/Sapphire/styles/bootstrapScoped.min.css" type="text/css" />');

    $J('#helpPopupDiv').dialog({
        autoOpen: false,
        height: 600,
        width: 900,
        modal: true,
        title: "Sapphire Resource Center",
        buttons: {
            "Done": function() {
                $J('#helpPopupDiv').dialog('close');
            }

        },
        close: function() {
            $J('#helpPopupDiv').dialog('destroy');
        }
    });
    var params = {};
    params.tme = Math.random();
    params.ScreenID = ScreenID;
    params.ProductId = ProductId;
    $J.get('/CommunityWebPortal/prodvid/CMSOutput.cfm', params, function() {}, 'html')
        .done(function(data) {
            $J('#helpPopupDiv').html(data);
            $J('#helpPopupDiv').dialog('open');
        })
        .fail(function(data) {
            alert('Error: An unexpected error occured.');
        });
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
function SearchTree(text){
    if(text.length == 0){
        return ClearSearch();
    }
    $J('#tree').hide();
    if($J('#SearchList').length){$J('#SearchList').remove();}
    $J('#sidetree').append('<ul id="SearchList" style="text-align:left;font-size: 0.8em;"></ul>');
    var namesArray = [];
    $J('li.filetree').each(function(){
        anchorText = $J.trim($J(this).find('a').text().toLowerCase());
        if($J(this).text().toLowerCase().indexOf(text.toLowerCase()) > 0 && $J(this).hasClass('expandable') === false && $J(this).hasClass('collapsable') === false){
            if($J.inArray(anchorText, namesArray) < 0){
                $J('#SearchList').append($J(this).clone());
                namesArray.push(anchorText);
            }
        }
    });
}
function ClearSearch(){
	$J('#tree').show();
	if($J('#SearchList').length){$J('#SearchList').remove();}
}
