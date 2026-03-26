const { Sequelize } = require('sequelize');

// Mocked locally for now with SQLite if Postgres URL is not provided
const sequelize = process.env.DATABASE_URL 
  ? new Sequelize(process.env.DATABASE_URL, {
      dialect: 'postgres',
      logging: false,
    })
  : new Sequelize({
      dialect: 'sqlite',
      storage: './creatoros-local.sqlite',
      logging: false,
    });

module.exports = sequelize;
