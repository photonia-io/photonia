import { default as axios } from "axios";

var oldPhotoName = '';
var oldPhotoDescription = '';

document.addEventListener('load', () => {
  photoName = document.getElementById('photo-name');

  photoName.addEventListener('focus', () => {
    oldPhotoName = photoName.innerText;
    if(oldPhotoName == '(no title)') {
      oldPhotoName = '';
      photoName.innerText = oldPhotoName;
    }
  });
  photoName.addEventListener('blur', updatePhotoName);
  photoName.addEventListener('keydown', (e) => {
    if(e.keyCode === 13) {
      e.preventDefault();
      photoName.blur();
    }
  });

  photoDescription = document.getElementById('photo-description');

  photoDescription.addEventListener('focus', () => {
    oldPhotoDescription = photoDescription.innerText;
    if(oldPhotoDescription == '(no description)') {
      oldPhotoDescription = '';
      photoDescription.innerText = oldPhotoDescription;
    }
  });
  photoDescription.addEventListener('blur', updatePhotoDescription);
})

function updatePhotoName(e) {
  var el = e.currentTarget;
  var newPhotoName = el.innerText.replace('<br>', '').trim();
  if(newPhotoName == '') {
    el.innerText = '(no title)';
  }
  if(newPhotoName != oldPhotoName) {
    var slug = el.dataset.photoSlug;
    updateResource('/photos/' + slug, {
      photo: {
        name: newPhotoName
      }
    })
  }
}

function updatePhotoDescription(e) {
  var el = e.currentTarget;
  var newPhotoDescription = el.innerText.trim();
  if(newPhotoDescription == '') {
    el.innerText = '(no description)';
  }
  if(newPhotoDescription != oldPhotoDescription) {
    var slug = el.dataset.photoSlug;
    updateResource('/photos/' + slug, {
      photo: {
        description: newPhotoDescription
      }
    })
  }
}

function updateResource(uri, params) {
  axios.patch(uri, params)
  .then(function (response) {
    console.log(response);
  })
  .catch(function (error) {
    console.log(error);
  });
}
