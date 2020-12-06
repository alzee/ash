;(function(){
  let xhr = new XMLHttpRequest();
  let url = 'README.md';
  xhr.onreadystatechange = function () {
    if(xhr.readyState === XMLHttpRequest.DONE){
      if(xhr.status === 200 || xhr.status === 0){
        document.getElementById('markdown').innerHTML = marked(xhr.responseText);
      }
    }
  };
  xhr.open('GET', url);
  xhr.send();
})();
