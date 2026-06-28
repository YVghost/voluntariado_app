module EcuadorValidations
  # Valida cédula ecuatoriana (10 dígitos)
  # Algoritmo módulo 10 del Registro Civil
  def self.cedula_valida?(cedula)
    return false unless cedula.to_s.match?(/^\d{10}$/)

    provincia = cedula[0..1].to_i
    return false unless provincia.between?(1, 24)

    tercer_digito = cedula[2].to_i
    return false if tercer_digito >= 6

    coeficientes = [ 2, 1, 2, 1, 2, 1, 2, 1, 2 ]
    suma = coeficientes.each_with_index.sum do |coef, i|
      resultado = cedula[i].to_i * coef
      resultado > 9 ? resultado - 9 : resultado
    end

    digito_verificador = cedula[9].to_i
    (10 - (suma % 10)) % 10 == digito_verificador
  end

  # Valida RUC ecuatoriano (13 dígitos)
  # Cubre personas naturales, sociedades privadas y entidades públicas
  def self.ruc_valido?(ruc)
    return false unless ruc.to_s.match?(/^\d{13}$/)

    provincia = ruc[0..1].to_i
    return false unless provincia.between?(1, 24)

    tercer_digito = ruc[2].to_i
    codigo_establecimiento = ruc[10..12]

    case tercer_digito
    when 0..5
      # Persona natural: primeros 10 dígitos = cédula válida + "001"
      cedula_valida?(ruc[0..9]) && codigo_establecimiento == "001"
    when 6
      # Entidad pública: tercer dígito 6, termina en "0001" ... usa 13 dígitos
      codigo_establecimiento == "001"
    when 9
      # Sociedad privada/extranjera: tercer dígito 9
      codigo_establecimiento == "001"
    else
      false
    end
  end
end

