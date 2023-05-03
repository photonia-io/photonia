import * as bulmaToast from 'bulma-toast'
import 'animate.css'

const toaster = (message, type = 'is-success') => {
  bulmaToast.toast(
    {
      message: message,
      type: type,
      duration: 3000,
      offsetTop: '55px',
      dismissible: false,
      pauseOnHover: true,
      closeOnClick: true,
      animate: {
        in: 'fadeInRight',
        out: 'fadeOutRight'
      }
    }
  )
}

export default toaster
