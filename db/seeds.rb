# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Создание seed данных..."

# Создание тестового пользователя
user = User.create!(
  email: 'test@example.com',
  name: 'Test User',
  password: 'password123',
  admin: true
)

puts "✅ Пользователь создан: #{user.email}"

# Создание категорий
categories = [
  { name: 'Работа', description: 'Рабочие задачи', color: '#dc3545' },
  { name: 'Личное', description: 'Личные дела', color: '#28a745' },
  { name: 'Учеба', description: 'Обучение и развитие', color: '#17a2b8' }
].map { |attrs| user.categories.create!(attrs) }

puts "✅ Категории созданы: #{categories.count}"

# Создание тегов
tags = [
  { name: 'Срочно', color: '#dc3545' },
  { name: 'Важно', color: '#ffc107' },
  { name: 'Идея', color: '#6f42c1' }
].map { |attrs| user.tags.create!(attrs) }

puts "✅ Теги созданы: #{tags.count}"

# Создание задач
tasks = [
  {
    title: 'Изучить Rails',
    description: 'Изучить основы Ruby on Rails',
    status: 'in_progress',
    category: categories.last,
    priority: 3,
    due_date: 1.week.from_now
  },
  {
    title: 'Создать TODO приложение',
    description: 'Разработать полнофункциональное приложение',
    status: 'pending',
    category: categories.first,
    priority: 5,
    due_date: 2.weeks.from_now
  }
].map { |attrs| user.tasks.create!(attrs) }

puts "✅ Задачи созданы: #{tasks.count}"

# Добавление тегов к задачам
tasks.first.tags << tags.first
tasks.first.tags << tags.second
tasks.second.tags << tags.second

puts "✅ Теги добавлены к задачам"

puts "\n🎉 Seed данные созданы успешно!"
puts "📊 Статистика:"
puts "   👤 Пользователи: #{User.count}"
puts "   📁 Категории: #{Category.count}"
puts "   🏷️  Теги: #{Tag.count}"
puts "   ✅ Задачи: #{Task.count}"
puts "   🔗 Связи: #{TaskTag.count}"
