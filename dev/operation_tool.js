$(document).ready(function(){
	$("#start_button").click(function (e) {
		console.log("start button clicked");
		window.location = 'skp:startOperation';
	});
	
	$("#abort_button").click(function (e) {
		console.log("abort button clicked");
		window.location = 'skp:abortOperation';
	});
});