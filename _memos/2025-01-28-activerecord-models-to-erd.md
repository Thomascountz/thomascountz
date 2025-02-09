---
layout: memo
title: ActiveRecord Models to a Mermaid ERD
date: '2025-01-28'
tags: [memo, rails, activerecord, mermaid]
---

Turn your ApplicationRecord models into a Mermaid ERD

```ruby
Rails.application.eager_load!

# Instead of all ApplicationRecord descendants, you can
# make an Array of only the models you care about
data = ApplicationRecord.descendants.each_with_object({}) do |model, data|
  model_name = model.name.upcase
  data[model_name] = {
    columns: model.columns.map { |column| [column.name, column.sql_type] },
    associations: model.reflect_on_all_associations.each_with_object({}) do |reflection, assoc_data|
      assoc_data[reflection.name] = {
        klass: reflection.class_name.upcase,
        relationship: reflection.macro
      }
    end
  }
end

# Intermediate step to save the data as JSON
File.open("data.json", "w") { |file| file.write(data.to_json) }

mermaid_erd = ["erDiagram"]

data.each do |table, details|
  columns = details[:columns].map { |name, type| "#{name} #{type}" }.join("\n  ")
  mermaid_erd << "#{table} {\n  #{columns}\n}"
end

data.each do |table, details|
  details[:associations]&.each do |association_name, association_details|
    other_table = association_details[:klass]
    case association_details[:relationship]
    when :belongs_to
      mermaid_erd << "#{table} ||--o{ #{other_table} : \"#{association_name}\""
    when :has_one
      mermaid_erd << "#{table} ||--|| #{other_table} : \"#{association_name}\""
    when :has_many
      mermaid_erd << "#{table} ||--o{ #{other_table} : \"#{association_name}\""
    end
  end
end

File.open("out.mermaid", "w") { |file| file.puts mermaid_erd.join("\n") }
```
