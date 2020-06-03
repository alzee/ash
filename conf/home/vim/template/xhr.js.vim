var xhr = new XMLHttpRequest();
xhr.onreadystatechange = function () {
	if(xhr.readyState === XMLHttpRequest.DONE){
		if(xhr.status === 200){
		}
	}
};
xhr.open('GET', '');
xhr.responseType='json';
//xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
xhr.send();
