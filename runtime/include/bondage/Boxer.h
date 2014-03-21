#pragma once

class boxer
  {
public:
  struct BoxedContainer;
  typedef BoxedContainer *BoxedData;
  typedef void (*Cleanup)(boxer *, BoxedData);

  struct BoxedContainer
    {
    const Reflect::Type *m_type;
    Cleanup m_clean;
    uint8_t m_data[1];
    };

  template <typename Traits> struct BoxedDataTyped : BoxedContainer
    {
    typedef typename Traits::TypeSize Size;
    typedef typename Traits::TypeAlignment Alignment;
    // Add storage for type - minus 1 as there is one byte in BoxedData.
    typename std::aligned_storage<Size::value-1, Alignment::value>::type m_extraData;
    };

  void initialise(BoxedContainer *data, const Reflect::Type *t, Cleanup clean)
    {
    data->m_type = t;
    data->m_clean = clean;
    }

  const Reflect::Type *getType(BoxedContainer *data)
    {
    return data->m_type;
    }

  void* getMemory(BoxedContainer *data)
    {
    return data->m_data;
    }

  const void* getMemory(BoxedContainer *data) const
    {
    return data->m_data;
    }

  template <typename Traits> static std::unique_ptr<BoxedContainer> create()
    {
    return std::unique_ptr<BoxedContainer>(new BoxedDataTyped<Traits>());
    }
  };

