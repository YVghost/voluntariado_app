import { Controller } from "@hotwired/stimulus"

const GEO_DATA = {
  "Ecuador": {
    "Quito": ["Carcelén","Cotocollao","El Condado","Calderón","Ponceano","Comité del Pueblo","La Delicia","Cochapamba","Concepción","Kennedy","San Isidro del Inca","Nayón","Zámbiza","Llano Chico","Iñaquito","Rumipamba","Jipijapa","Mariscal Sucre","Belisario Quevedo","La Floresta","Itchimbía","San Juan","Centro Histórico","La Libertad","Chilibulo","La Magdalena","Solanda","La Argelia","Turubamba","Quitumbe","Guamaní","Chillogallo"],
    "Guayaquil": ["Tarqui","Urdesa","Kennedy","Alborada","Sauces","Mapasingue","Bastión Popular","Monte Sinaí","Durán","Samborondón","La Aurora","Daule"],
    "Cuenca": ["El Sagrario","San Blas","Gil Ramírez Dávalos","El Batán","Huayna Cápac","Yanuncay","Bellavista","San Sebastián","Sucre","Cañaribamba","Totoracocha","Monay"],
    "Ambato": ["La Matriz","La Merced","Huachi Grande","Huachi Loreto","Izamba","Picaihua","Totoras"],
    "Loja": ["El Sagrario","El Valle","Sucre","Punzara"],
    "Manta": ["Tarqui","Los Esteros","Manta","Umiña"],
    "Ibarra": ["El Sagrario","San Francisco","La Dolorosa del Priorato","Caranqui","Alpachaca"],
    "Riobamba": ["Lizarzaburu","Maldonado","Veloz","Yaruquíes","Velasco"],
    "Esmeraldas": ["5 de Agosto","Bartolomé Ruiz","Luis Tello"],
    "Portoviejo": ["18 de Octubre","12 de Marzo","Andrés de Vera"]
  },
  "Colombia": {
    "Bogotá": ["Chapinero","Usaquén","Suba","Engativá","Bosa","Kennedy","Fontibón","Puente Aranda","La Candelaria","Teusaquillo","Mártires","Antonio Nariño"],
    "Medellín": ["El Poblado","Laureles","Envigado","Belén","Robledo","Castilla","Manrique","Aranjuez","La Candelaria"],
    "Cali": ["San Antonio","Granada","El Peñón","Aguablanca","Ciudad Jardín","Chipichape"],
    "Barranquilla": ["El Prado","Riomar","Las Américas","Sur Occidente"],
    "Cartagena": ["Bocagrande","Getsemaní","El Centro","Manga"]
  },
  "Perú": {
    "Lima": ["Miraflores","San Isidro","Barranco","Surco","San Borja","La Molina","Lince","Breña","El Agustino","Villa El Salvador","Comas","Los Olivos"],
    "Arequipa": ["Cayma","Cercado","José Luis Bustamante","Miraflores","Mariano Melgar"],
    "Trujillo": ["Trujillo","El Porvenir","La Esperanza","Florencia de Mora"],
    "Cusco": ["Cusco","San Sebastián","San Jerónimo","Santiago"]
  },
  "Argentina": {
    "Buenos Aires": ["Palermo","Belgrano","Recoleta","Caballito","Flores","San Telmo","La Boca","Barracas","Almagro","Villa Crespo","Núñez","Colegiales"],
    "Córdoba": ["Nueva Córdoba","Güemes","Alberdi","General Paz","Cerro de las Rosas"],
    "Rosario": ["Centro","Pichincha","Las Delicias","Fisherton"],
    "Mendoza": ["Ciudad","Godoy Cruz","Guaymallén","Las Heras"]
  },
  "Chile": {
    "Santiago": ["Providencia","Ñuñoa","Las Condes","Vitacura","Maipú","La Florida","San Bernardo","Pudahuel","Cerro Navia","Recoleta"],
    "Valparaíso": ["Valparaíso","Viña del Mar","Concón"],
    "Concepción": ["Concepción","Talcahuano","San Pedro de la Paz"]
  },
  "México": {
    "Ciudad de México": ["Coyoacán","Xochimilco","Tlalpan","Benito Juárez","Cuauhtémoc","Miguel Hidalgo","Iztapalapa","Gustavo A. Madero","Azcapotzalco"],
    "Guadalajara": ["Zapopan","Tonalá","Tlaquepaque","Tlajomulco"],
    "Monterrey": ["San Pedro Garza García","San Nicolás de los Garza","Guadalupe","Apodaca"]
  },
  "Venezuela": {
    "Caracas": ["Chacao","El Hatillo","Baruta","Libertador","Sucre"],
    "Maracaibo": ["San Francisco","Maracaibo"]
  },
  "Bolivia": {
    "La Paz": ["Sopocachi","Miraflores","San Pedro","Zona Sur","El Alto"],
    "Santa Cruz de la Sierra": ["Plan 3000","Equipetrol","Las Palmas"]
  }
}

export default class extends Controller {
  static targets = ["country", "city", "sector", "currentValues", "locationInput"]

  connect() {
    this.#populateCountries()
    if (this.hasCurrentValuesTarget) {
      const cv = this.currentValuesTarget.dataset
      if (cv.country) {
        this.countryTarget.value = cv.country
        this.#populateCities(cv.country, cv.city)
        if (cv.city) {
          this.#populateSectors(cv.country, cv.city, cv.sector)
        }
      }
    }
    this.#syncLocationInput()
  }

  loadCities() {
    const country = this.countryTarget.value
    this.#populateCities(country)
    this.#resetSelect(this.sectorTarget, "— primero seleccioná una ciudad —")
    this.#syncLocationInput()
  }

  loadSectors() {
    const country = this.countryTarget.value
    const city    = this.cityTarget.value
    this.#populateSectors(country, city)
    this.#syncLocationInput()
  }

  syncOnSectorChange() {
    this.#syncLocationInput()
  }

  #syncLocationInput() {
    if (!this.hasLocationInputTarget) return
    const country = this.countryTarget.value || ""
    const city    = this.cityTarget.value    || ""
    const sector  = this.sectorTarget.value  || ""
    const parts   = [country, city, sector].filter(v => v)
    this.locationInputTarget.value = parts.join(", ")
  }

  #populateCountries() {
    const countries = Object.keys(GEO_DATA).sort()
    this.countryTarget.innerHTML =
      '<option value="">Seleccioná un país</option>' +
      countries.map(c => `<option value="${c}">${c}</option>`).join("")
  }

  #populateCities(country, selectedCity = null) {
    if (!country || !GEO_DATA[country]) {
      this.#resetSelect(this.cityTarget, "— primero seleccioná un país —")
      return
    }
    const cities = Object.keys(GEO_DATA[country]).sort()
    this.cityTarget.innerHTML =
      '<option value="">Seleccioná una ciudad</option>' +
      cities.map(c => `<option value="${c}" ${c === selectedCity ? "selected" : ""}>${c}</option>`).join("")
  }

  #populateSectors(country, city, selectedSector = null) {
    if (!country || !city || !GEO_DATA[country]?.[city]) {
      this.#resetSelect(this.sectorTarget, "— primero seleccioná una ciudad —")
      return
    }
    const sectors = GEO_DATA[country][city]
    this.sectorTarget.innerHTML =
      '<option value="">Seleccioná un sector</option>' +
      sectors.map(s => `<option value="${s}" ${s === selectedSector ? "selected" : ""}>${s}</option>`).join("")
  }

  #resetSelect(el, placeholder) {
    el.innerHTML = `<option value="">${placeholder}</option>`
  }
}
