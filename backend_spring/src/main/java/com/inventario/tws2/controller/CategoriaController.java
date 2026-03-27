package com.inventario.tws2.controller;

import com.inventario.tws2.model.Categoria;
import com.inventario.tws2.repository.CategoriaRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
@SuppressWarnings("null")
public class CategoriaController {

    @Autowired
    private CategoriaRepository categoriaRepository;

    @GetMapping("/categorias")
    public List<Categoria> getAll() {
        return categoriaRepository.findAll();
    }

    @PostMapping("/categorias")
    public Categoria create(@Valid @RequestBody Categoria categoria) {
        Categoria guardada = categoriaRepository.save(categoria);
        if (guardada == null) throw new RuntimeException("Error al guardar categoría");
        return guardada;
    }

    @PutMapping("/categorias/{id}")
    public ResponseEntity<Categoria> update(@PathVariable Long id, @Valid @RequestBody Categoria details) {
        return categoriaRepository.findById(id)
                .map(categoria -> {
                    categoria.setNombre(details.getNombre());
                    categoria.setStockMinimo(details.getStockMinimo());
                    return ResponseEntity.ok(categoriaRepository.save(categoria));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/categorias/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        return categoriaRepository.findById(id)
                .map(categoria -> {
                    categoriaRepository.delete(categoria);
                    return ResponseEntity.ok().<Void>build();
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
