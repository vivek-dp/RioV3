function parseString(inputStr){
    return inputStr.replace(/['"]+/g, '')
}

function createParamString(params) {
    str = "";
    str += "@"+params.join("@");
    return str;
}
function updateRoomNames(){
    console.log("UpdateRoomNames");
    window.location.href='skp:rioGetRoomNames';
}
function jsCreateRoom() {
    console.log("create Room called"+$(this).data.params)
    console.log("serialize "+JSON.stringify($('room_form').serialize));
    console.log("Room name : "+JSON.stringify(document.getElementById("CR_room_name")));

    room_name = JSON.stringify(document.getElementById("CR_room_name").value);
    wall_height = JSON.stringify(document.getElementById("CR_wall_height").value);
    door_height = JSON.stringify(document.getElementById("CR_door_height").value);
    
    window_height = JSON.stringify(document.getElementById("CR_window_height").value);
    window_offset = JSON.stringify(document.getElementById("CR_window_offset").value);
    //wall_color = JSON.stringify(document.getElementById("colorpalettediv").value)
    console.log("Room : "+document.getElementById("CR_room_name").value+"--"+wall_height+door_height)
    //window.location = 'skp:rioCreateRoom'

    paramStr = createParamString([room_name, wall_height, door_height, window_height, window_offset])
    console.log("PParam string : "+paramStr)
    window.location.href = 'skp:rioCreateRoom@'+paramStr;
    //sketchup.rioCreateRoom(10, 22);
}//Create room 

function jsDeleteRoomComponents() {
	room_name = JSON.stringify(document.getElementById("CR_room_name").value);
    console.log("Deleting room components : "+room_name.toString())
    window.location.href = 'skp:rioRemoveRoomComponents@'+parseString(room_name);
}

function multiDeleteRooms() {
    var selectedValues=[];
    $("#room-name-list :selected").each(function(){
        selectedValues.push($(this).val()); 
    });
    console.log(selectedValues);
    window.location.href = 'skp:rioDeleteMultiRoom@'+selectedValues;
    //$("#room-name-list").empty();
    //updateRoomNames();
}

function passRoomNames(roomNames) {
    console.log("roomNames.."+roomNames);
	$("#room-name-list").empty();
    var roomList = document.getElementById("room-name-list");
	console.log("roomName ..."+roomNames[0]);
	//var roomNamesArray = roomNames.split(",");
	//roomList.empty();
	for (i = 0; i < roomNames.length; i++)
	{
		console.log("Room Name : "+roomNames[i])
		var optn = document.createElement("OPTION");
		optn.text = roomNames[i];
		optn.value = roomNames[i];
		roomList.options.add(optn);
	}
}
