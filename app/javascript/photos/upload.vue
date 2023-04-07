<template>
  <div class="container">
    <h1 class="title mt-5 mb-0">Upload Photos</h1>
    <hr class="is-hidden-touch mt-2 mb-4">
    <div v-show="$refs.upload && $refs.upload.dropActive" class="drop-active">
		  <h3>Drop files here to upload</h3>
    </div>
    <div v-show="!files.length" class="block drop-zone has-text-centered">
      <h4>Drop files anywhere to upload<br/>or</h4>
      <label for="photo[image]" class="button is-primary">
        <span class="icon is-small">
          <i class="fa fa-plus" aria-hidden="true"></i>
        </span>
        <span>Select Files</span>
      </label>
    </div>
    <div
      class="box"
      v-for="file in files"
      :key="file.id"
    >
      <div class="columns">
        <div
          class="column is-12"
          v-if="file.active"
        >
          <progress
            class="progress is-small is-primary"
            :value="file.progress"
            max="100"
          >
            {{file.progress}}%
          </progress>
        </div>
      </div>
      <div class="columns">
        <div class="column is-2">
          <img
            v-if="file.thumb"          
            :src="file.thumb"
            :alt="file.name"
            style="max-width: 100%; max-height: 100%;">
        </div>
        <div class="column is-10">
          <div class="columns">
            <div class="column is-half">
              <div class="field">
                <label class="label is-small">
                  Name
                  <div class="control">
                    <input
                      type="text"
                      class="input is-small"
                      v-model="file.data['photo[name]']"
                    >
                  </div>
                </label>
              </div>
              <div class="field">
                <label class="label is-small">
                  Description
                  <div class="control">
                    <textarea
                      class="textarea is-small"
                      v-model="file.data['photo[description]']"
                    >
                    </textarea>
                  </div>
                </label>
              </div>
            </div>
            <div class="column is-half">
              <p>
                <span>Size: {{formatSize(file.size)}}</span>
              </p>
              <p>
                Status: 
                <span v-if="file.error">{{file.error}}</span>
                <span v-else-if="file.success">Uploaded Successfully</span>
                <span v-else-if="file.active">Uploading...</span>
                <span v-else-if="!!file.error">{{file.error}}</span>
                <span v-else>Ready to upload</span>
              </p>
              <div class="buttons">
                <button type="button" class="button is-danger" @click.prevent="$refs.uploader.remove(file)">
                  <span class="icon is-small">
                    <i class="fa fa-trash" aria-hidden="true"></i>
                  </span>
                  <span>Remove</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="columns">
      <div class="column is-half">
        <div class="buttons">
        <file-upload
          name="photo[image]"
          class="button is-primary"
          post-action="/photos"
          extensions="jpg,jpeg,png,gif,webp"
          accept="image/jpeg,image/png,image/gif,image/webp"
          :multiple="true"
          :headers="{ 'Authorization': tokenStore.authorization }"
          v-model="files"
          @input-filter="inputFilter"
          @input-file="inputFile"
          ref="uploader"
          :drop="true"
        >
          <span class="icon is-small">
            <i class="fa fa-plus" aria-hidden="true"></i>
          </span>
          <span>Select Files</span>
        </file-upload>
        <button
          type="button"
          class="button is-success"
          v-if="!uploader || !uploader.active"
          @click.prevent="uploader.active = true"
          :disabled="files.length === 0"
        >
          <span class="icon is-small">
            <i class="fa fa-arrow-up" aria-hidden="true"></i>
          </span>
          <span>Upload All</span>
        </button>
        <button
          type="button"
          class="btn btn-danger"
          v-else
          @click.prevent="uploader.active = false"
        >
          <span class="icon is-small">
            <i class="fa fa-stop" aria-hidden="true"></i>
          </span>
          <span>Stop Upload</span>
        </button>

        </div>
      </div>
      <div class="column is-half">
        <div class="buttons is-pulled-right">
          <button
            type="button"
            class="button is-danger"
            @click.prevent="$refs.uploader.clear()"
            :disabled="files.length === 0"
          >
            <span class="icon is-small">
              <i class="fa fa-trash" aria-hidden="true"></i>
            </span>
            <span>Remove All</span>
          </button>
          <button
            type="button"
            class="button is-danger"
            @click.prevent="removeUploadedFiles()"
            :disabled="removeUploadedFilesDisabled()"
          >
            <span class="icon is-small">
              <i class="fa fa-broom" aria-hidden="true"></i>
            </span>
            <span>Remove Uploaded</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
  .drop-zone {
    background-color: #f5f5f5;
    border: 2px dashed #ccc;
    border-radius: 5px;
    padding: 20px;
    text-align: center;
  }  
</style>

<script setup>
  import { ref } from 'vue';

  import { useTokenStore } from '../stores/token.js'
  import { useTitle } from 'vue-page-title';
  import FileUpload from 'vue-upload-component';

  useTitle('Upload Photos');

  const uploader = ref(null);
  const files = ref([]);
  const tokenStore = useTokenStore();

  const inputFilter = function(newFile, oldFile, prevent) {
    if (newFile && !oldFile) {
      if (/(\/|^)(Thumbs\.db|desktop\.ini|\..+)$/.test(newFile.name)) {
        return prevent()
      }
      
      if (/\.(php5?|html?|jsx?)$/i.test(newFile.name)) {
        return prevent()
      }

      if (newFile && newFile.error === "" && newFile.file && (!oldFile || newFile.file !== oldFile.file)) {
        // Create a blob field
        newFile.blob = ''
        let URL = (window.URL || window.webkitURL)
        if (URL) {
          newFile.blob = URL.createObjectURL(newFile.file)
        }
        // Thumbnails
        newFile.thumb = ''
        if (newFile.blob && newFile.type.substr(0, 6) === 'image/') {
          newFile.thumb = newFile.blob
        }
        // Add some extra info
        newFile.data = {
          'photo[name]': newFile.name,
          'photo[description]': '',
        }
      }
    }
  }

  const inputFile = function(newFile, oldFile) {
    if (newFile && !oldFile) {
      // add
      console.log('add', newFile)
    }
    if (newFile && oldFile) {
      // update
      console.log('update', newFile)
    }
    if (!newFile && oldFile) {
      // remove
      console.log('remove', oldFile)
    }
  }

  const removeUploadedFiles = function() {
    files.value.forEach(function(file) {
      if (file.success) {
        uploader.value.remove(file)
      }
    })
  }

  const removeUploadedFilesDisabled = function() {
    return !files.value.some((file) => file.success)
  }

  const formatSize = function(size) {
    if (size > 1024 * 1024 * 1024 * 1024) {
      return (size / 1024 / 1024 / 1024 / 1024).toFixed(2) + ' TB'
    } else if (size > 1024 * 1024 * 1024) {
      return (size / 1024 / 1024 / 1024).toFixed(2) + ' GB'
    } else if (size > 1024 * 1024) {
      return (size / 1024 / 1024).toFixed(2) + ' MB'
    } else if (size > 1024) {
      return (size / 1024).toFixed(2) + ' KB'
    }
    return size.toString() + ' B'
  }
</script>
