Sequelize = require 'sequelize'
module.exports.model = (sequelize) ->
    sequelize.define(
        "Song",
        {
            # Where is came from
            contentSource:
                type: Sequelize.STRING(70)
                defaultValue: 'dropbox'
                allowNull: false
            contentSourceId:
                type: Sequelize.STRING(255)
                allowNull: false
            contentSourceHash:
                type: Sequelize.STRING(255)

            # Metadata columns
            album: Sequelize.STRING(255)
            genre: Sequelize.ARRAY(Sequelize.TEXT)
            title: Sequelize.STRING(255)
            artist: Sequelize.ARRAY(Sequelize.TEXT)
            discnumber: Sequelize.JSON
            tracknumber: Sequelize.JSON
            albumartistsort: Sequelize.ARRAY(Sequelize.TEXT)
        },
        {
            tableName:"songs"
        }
    )

module.exports.associations = (sequelize) ->
    User = sequelize.model 'User'
    Song = sequelize.model 'Song'

    User.hasMany Song, as:"songs"