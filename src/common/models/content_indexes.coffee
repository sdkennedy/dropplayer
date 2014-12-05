Sequelize = require 'sequelize'
module.exports.model = (sequelize) ->
    ContentIndex = sequelize.define(
        "ContentIndex",
        {
            contentSource:
                type: Sequelize.STRING(70)
                defaultValue: 'dropbox'
                allowNull: false
            endedAt:
                type: Sequelize.DATE
            itemsIndexed:
                type:Sequelize.INTEGER
                default:0
            itemsRemoved:
                type:Sequelize.INTEGER
                default:0
        },
        {
            tableName:"content_indexes"
            classMethods:
                getUnfinishedIndex: (userId, source) ->
                    ContentIndex.find where:{ UserId:userId, endedAt:null }

        }
    )

module.exports.associations = (sequelize) ->
    ContentIndex = sequelize.model 'ContentIndex'
    User = sequelize.model 'User'

    User.hasMany ContentIndex, as:"contentIndexes"