Sequelize = require 'sequelize'
module.exports.model= (sequelize) ->
    sequelize.define(
        "User",
        {
            primaryEmail:
                type:Sequelize.STRING(255)
                unique:true
                allowNull:false
                validate:
                    isEmail:true
            primaryDisplayName:
                type:Sequelize.STRING(255)
                allowNull:false
        },
        {
            tableName:"users"
        }
    )