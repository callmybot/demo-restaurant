<template>
  <q-page padding class="container">
    <section :key="category" v-for="(products, category) in menu">
      <h2 class="text-h4">{{ category }}</h2>
      <div class="row q-col-gutter-lg">
        <div :key="index" v-for="(product, index) in products" class="col-12 col-md-6">
          <q-card flat>
            <q-card-section>
              <div class="text-h6">{{ product.name }} – {{ product.price / 100 }} kr</div>
            </q-card-section>

            <q-card-section v-if="product.description || product.allergens">
              <div class="text-subtitle1">{{ product.description }}</div>
              <div v-if="product.allergens" class="text-caption">
                Allergener: {{ product.allergens.join(', ') }}
              </div>
            </q-card-section>
          </q-card>
        </div>
      </div>
    </section>
  </q-page>
</template>

<script setup>
import menu from 'assets/menu.json' with { type: 'json' }
</script>
