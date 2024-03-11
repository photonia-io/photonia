# 2023.11.07 - 0.12.3

### Relevant PRs

- [Photo date tweaks](https://github.com/photonia-io/photonia/pull/609)

### Tasks to be run

`cap production photos:fix_taken_at`

# 2023.11.07 - 0.12.2

### Relevant PRs

- [EXIF related fixes](https://github.com/photonia-io/photonia/pull/608)

### Tasks to be run

`cap production photos:reset_exif_and_timezone` - no need to run as it was part of photos:fix_exif in 0.12.0

`cap production photos:fix_exif`

# 2023.11.06 - 0.12.0

### Relevant PRs

- [Settings pages & EXIF improvements](https://github.com/photonia-io/photonia/pull/607)

### Tasks to be run

`cap production users:make_admin[user@email.com]`

`cap production photos:fix_exif`
